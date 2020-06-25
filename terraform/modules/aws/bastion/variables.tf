variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the cluster."
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster and the bastion."
  type        = string
}

variable "subnet_id" {
  description = "The subnet IDs into which the basstion EC2 Instanc should be deployed."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instance to run the bastion server."
  type        = string
}

variable "bastion_name" {
  description = "The name of the bastion and all its resources."
  type        = string
}

variable "ign_users_list" {
  type = list(string)
}
