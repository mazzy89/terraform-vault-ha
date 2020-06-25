variable "aws_region" {
  description = "AWS region where the Vault cluster is deployed."
  type        = string
  default     = "us-east-1"
}

variable "aws_availability_zones" {
  description = "List of availability zones where the Vault cluster is deployed."
  type        = list(string)

  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}

variable "aws_kms_key" {
  description = "The ID of KMS key used for unsealing the Vault cluster"
  type        = string
  default     = null
}

variable "flatcar_version" {
  description = "Flatcar version"
  type        = string
  default     = "2512.2.0"
}

variable "vpc_cidr_block" {
  description = "The type of EC2 Instance to run Vault servers"
  type        = string
  default     = "192.168.100.0/24"
}

variable "bastion_instance_type" {
  description = "The type of EC2 Instance to run the bastion server."
  type        = string
  default     = "t3.micro"
}

variable "bastion_name" {
  description = "The name assigned to the bastion and all its resources."
  type        = string
  default     = "bastion.cluster.local"
}

variable "tls_dns_names" {
  description = "List of DNS names for which the certificate will be valid (e.g. vault.service.consul, foo.example.com)."
  type        = list(string)
  default     = []
}

variable "tls_ip_addresses" {
  description = "List of IP addresses for which the certificate will be valid (e.g. 127.0.0.1)."
  type        = list(string)
  default = [
    "127.0.0.1"
  ]
}

variable "tls_organization_name" {
  description = "The name of the organization to associate with the certificates (e.g. Acme Co)."
  type        = string
  default     = ""
}

variable "tls_ca_common_name" {
  description = "The common name to use in the subject of the CA certificate (e.g. acme.co cert)."
  type        = string
  default     = ""
}

variable "tls_common_name" {
  description = "The common name to use in the subject of the certificate (e.g. acme.co cert)."
  type        = string
  default     = ""
}

variable "tls_validity_period_hours" {
  description = "The number of hours after initial issuing that the certificate will become invalid."
  type        = number
  default     = 8760
}

variable "vault_cluster_name" {
  description = "Name the Vault server cluster and all of its associated resources"
  type        = string
  default     = "vault.cluster.local"
}

variable "vault_instance_type" {
  description = "The type of EC2 Instance to run Vault servers"
  type        = string
  default     = "t3.small"
}

variable "vault_cluster_size" {
  description = "The number of Vault server nodes to deploy. We strongly recommend using 3 or 5."
  type        = number
  default     = 3
}

variable "vault_iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
  type        = string
  default     = "vault-cluster-local"
}

variable "vault_version" {
  description = "The version of the Vault Server."
  type        = string
  default     = "1.4.2"
}

variable "vault_recovery_s3_bucket" {
  type    = string
  default = ""
}

variable "vault_recovery_s3_prefix" {
  type    = string
  default = "vault.cluster.local/"
}

variable "node_exporter_version" {
  description = "The version of the Node Exporter."
  type        = string
  default     = "v0.18.1"
}
