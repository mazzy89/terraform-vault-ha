# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

locals {
  aws_azs_length = length(var.aws_availability_zones)

  # For each number in range, extend the CIDR prefix of the
  # requested VPC to produce a subnet CIDR prefix.
  # For the default value of availability zones and a VPC CIDR prefix
  # of 192.168.100.0/24, this would produce:
  #   ["192.168.100.0/27", "192.168.100.32/27", "192.168.100.64/27"]
  vpc_private_subnets = [
    for num in range(local.aws_azs_length) :
    cidrsubnet(var.vpc_cidr_block, 3, num)
  ]

  # For each number in range, extend the CIDR prefix of the
  # requested VPC to produce a subnet CIDR prefix.
  # For the default value of availability zones and a VPC CIDR prefix
  # of 192.168.100.0/24, this would produce:
  #   ["192.168.100.96/27", "192.168.100.128/27", "192.168.100.160/27"]
  vpc_public_subnets = [
    for num in range(local.aws_azs_length, local.aws_azs_length * 2) :
    cidrsubnet(var.vpc_cidr_block, 3, num)
  ]
}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "flatcar" {
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["Flatcar-stable-${var.flatcar_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["075585003325"]
}

# ---------------------------------------------------------------------------------------------------------------------
# LOAD THE LIST OF ALL THE USERS
# ---------------------------------------------------------------------------------------------------------------------
data "local_file" "users" {
  filename = "../../../users.yaml"
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE KSM KEY FOR THE AUTO UNSEAL - IN CASE THE USER DOES NOT PROVIDE A KMS KEY AS INPUT
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "auto_unseal_key" {
  count = var.aws_kms_key == null ? 1 : 0

  description = "Vault Auto Unseal key for ${var.vault_cluster_name}"

  # TODO(mazzy89): create a policy to allow access to EC2 instance via IAM instance profile

  tags = {
    Name    = var.vault_cluster_name
    Cluster = var.vault_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE TLS CERTS
# ---------------------------------------------------------------------------------------------------------------------

module "tls" {
  source = "../../terraform/modules/tls"

  dns_names    = var.tls_dns_names
  ip_addresses = var.tls_ip_addresses

  organization_name = var.tls_organization_name
  ca_common_name    = var.tls_ca_common_name
  common_name       = var.tls_common_name

  validity_period_hours = var.tls_validity_period_hours
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE INTERNAL ALB
# ---------------------------------------------------------------------------------------------------------------------
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "${replace(var.vault_cluster_name, ".", "-")}-alb"
  description = "Security group for Vault ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8200
      to_port     = 8200
      protocol    = "tcp"
      description = "Vault Health"
      cidr_blocks = var.vpc_cidr_block
    },
  ]

  egress_rules = ["all-all"]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = replace(var.vault_cluster_name, ".", "-")

  load_balancer_type = "application"
  internal           = true

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  security_groups = [module.alb_security_group.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "hz-"
      backend_protocol = "HTTPS"
      backend_port     = 8200
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 5
        path                = "/v1/sys/health?standbyok=true&prfstandbyok=true"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 3
        protocol            = "HTTPS"
        matcher             = "200"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 8200
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Name    = var.vault_cluster_name
    Cluster = var.vault_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE IGNITION PARTS
# ---------------------------------------------------------------------------------------------------------------------

module "ignition" {
  source = "../../terraform/modules/ignition"

  aws_region             = var.aws_region
  aws_availability_zones = var.aws_availability_zones

  kms_key = var.aws_kms_key == null ? element(
    aws_kms_key.auto_unseal_key.*.id,
    0,
  ) : var.aws_kms_key

  cluster_size = var.vault_cluster_size

  vault_server_crt_pem = module.tls.vault_cert_pem
  vault_server_key_pem = module.tls.vault_key_pem

  vault_version         = var.vault_version
  node_exporter_version = var.node_exporter_version

  users = data.local_file.users.content

  aws_s3_bucket        = var.vault_recovery_s3_bucket
  aws_s3_prefix        = var.vault_recovery_s3_prefix
  aws_loadbalancer_dns = module.alb.this_lb_dns_name
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT SERVER CLUSTER, GENERATE TLS, AND THE IGNITION CONFIG
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.24.0"

  name = var.vault_cluster_name

  cidr = var.vpc_cidr_block
  azs  = var.aws_availability_zones

  private_subnets = local.vpc_private_subnets
  public_subnets  = local.vpc_public_subnets

  # One NAT Gateway per subnet
  #
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name    = var.vault_cluster_name
    Cluster = var.vault_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY BASTION
# ---------------------------------------------------------------------------------------------------------------------

module "bastion" {
  source = "../../terraform/modules/bastion"

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  ami_id        = data.aws_ami.flatcar.id
  instance_type = var.bastion_instance_type

  bastion_name = var.bastion_name

  # Users
  ign_users_list = module.ignition.users_list
}


# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE VAULT SERVER CLUSTER WITH RAFT
# ---------------------------------------------------------------------------------------------------------------------

module "cluster" {
  source = "../../terraform/modules/cluster"

  vpc_id                 = module.vpc.vpc_id
  aws_availability_zones = var.aws_availability_zones
  subnet_ids             = module.vpc.private_subnets

  ami_id                    = data.aws_ami.flatcar.id
  instance_type             = var.vault_instance_type
  iam_instance_profile      = var.vault_iam_instance_profile
  bastion_security_group_id = module.bastion.security_group_id

  kms_key = var.aws_kms_key == null ? element(
    aws_kms_key.auto_unseal_key.*.id,
    0,
  ) : var.aws_kms_key

  aws_lb_security_group_id         = module.alb_security_group.this_security_group_id
  aws_lb_target_group_vault_health = module.alb.target_group_arns[0]

  cluster_name = var.vault_cluster_name
  cluster_size = var.vault_cluster_size

  # Filesystem
  ign_vault_filesystem = module.ignition.vault_filesystem

  # Files
  ign_vault_ca_crt         = module.ignition.vault_ca_crt
  ign_vault_ca_key         = module.ignition.vault_ca_key
  ign_vault_config_list    = module.ignition.vault_config_list
  ign_vault_cluster_config = module.ignition.vault_cluster_config
  ign_vault_hostname_list  = module.ignition.vault_hostname_list

  # Systemd servicees
  ign_vault_mount                        = module.ignition.vault_mount
  ign_vault_service                      = module.ignition.vault_service
  ign_vault_operator_unseal_service_list = module.ignition.vault_operator_unseal_service_list
  ign_vault_operator_configure_service   = module.ignition.vault_operator_configure_service
  ign_node_exporter_service              = module.ignition.node_exporter_service

  # Dropin
  ign_update_ca_certificates_dropin = module.ignition.update_ca_certificates_dropin

  # Users/Groups
  ign_users_list = module.ignition.users_list

  # Vault User/Group
  ign_vault_user  = module.ignition.vault_user
  ign_vault_group = module.ignition.vault_group

  # Directories
  ign_directories_list = module.ignition.directories_list
}
