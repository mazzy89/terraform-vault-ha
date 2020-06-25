variable "aws_region" {
  type = string
}

variable "kms_key" {
  type = string
}

variable "aws_availability_zones" {
  description = "List of availability zones where the Vault cluster is deployed."
  type        = list(string)
  default     = []
}

variable "vault_version" {
  description = "The version of the Vault Server."
  type        = string
}

variable "node_exporter_version" {
  description = "The version of the Node Exporter."
  type        = string
}

variable "vault_storage_path" {
  description = "The file system path where all the Vault data gets stored."
  type        = string
  default     = "/etc/vault/data"
}

variable "cluster_size" {
  description = "The number of Vault server nodes to deploy. We strongly recommend using 3 or 5."
  type        = number
}

variable "vault_server_crt_pem" {
  description = "Path to the certificate for TLS."
  type        = string
  default     = null
}

variable "vault_server_key_pem" {
  description = "Path to the private key for the certificate."
  type        = string
  default     = null
}

variable "aws_s3_bucket" {
  description = "The name of the AWS S3 bucket to store encrypted keys in."
  type        = string
}

variable "aws_s3_prefix" {
  description = "The prefix to use for storing values in AWS S3."
  type        = string
}

variable "aws_loadbalancer_dns" {
  type = string
}

variable "users" {
  description = "Users file containing SSH public keys and permissions."
  type        = string
  default     = null
}
