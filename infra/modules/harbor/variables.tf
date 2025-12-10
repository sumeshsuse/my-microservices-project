variable "ami_id" {
  type        = string
  description = "AMI ID for Harbor instance"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Harbor will run"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Harbor"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into Harbor"
}
