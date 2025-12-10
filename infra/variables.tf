variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name to SSH into instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Harbor"
  type        = string
  default     = "t3.medium"
}

variable "control_instance_type" {
  description = "EC2 instance type for control plane"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2 instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "harbor_version" {
  description = "Harbor version to install"
  type        = string
  default     = "2.10.0"
}

