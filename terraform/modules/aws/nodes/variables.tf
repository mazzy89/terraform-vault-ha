variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the cluster"
  type        = string
}

variable "aws_availability_zones" {
  description = "List of availability zones where the Vault cluster is deployed."
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster and the bastion."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instance to run Vault servers"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs into which the EC2 Instances should be deployed. You should typically pass in one subnet ID per node in the cluster_size variable. We strongly recommend that you run Vault in private subnets."
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
  type        = string
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 50
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}


variable "cluster_name" {
  description = "Name the Vault server cluster and all of its associated resources"
  type        = string
}

variable "cluster_size" {
  description = "The number of Vault server nodes to deploy. We strongly recommend using 3 or 5."
  type        = number
}

variable "bastion_security_group_id" {
  description = "The ID of the Security Group of the bastion host."
  type        = string
}

variable "kms_key" {
  description = "KMS Key to encrypt volumes containing Vault data."
  type        = string
  default     = ""
}

variable "ign_vault_filesystem" {
  type = string
}

variable "ign_vault_ca_crt" {
  type = string
}

variable "ign_vault_ca_key" {
  type = string
}

variable "ign_vault_config_list" {
  type = list(string)
}

variable "ign_vault_cluster_config" {
  type = string
}

variable "ign_vault_mount" {
  type = string
}

variable "ign_vault_service" {
  type = string
}

variable "ign_vault_operator_unseal_service_list" {
  type = list(string)
}

variable "ign_vault_operator_configure_service" {
  type = string
}

variable "ign_node_exporter_service" {
  type = string
}

variable "ign_update_ca_certificates_dropin" {
  type = string
}

variable "ign_users_list" {
  type = list(string)
}

variable "ign_vault_user" {
  type = string
}

variable "ign_vault_group" {
  type = string
}

variable "ign_directories_list" {
  type = list(string)
}

variable "ign_vault_hostname_list" {
  type = list(string)
}

variable "aws_lb_target_group_vault_health" {
  type    = string
  default = null
}

variable "aws_lb_security_group_id" {
  type = string
}
