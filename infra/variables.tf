variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_type" {
  description = "Instance type for Harbor EC2"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into Harbor"
  type        = string
}

# 🔴 NEW VARIABLE (REQUIRED)
variable "allowed_client_cidr" {
  description = "CIDR allowed for Docker HTTPS probe on 443 (your public IP /32)"
  type        = string
}
