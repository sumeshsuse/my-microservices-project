variable "ami_id" {
  type        = string
  description = "AMI ID for Kubernetes nodes"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the cluster"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into nodes"
}

variable "control_instance_type" {
  type        = string
  description = "Instance type for control plane"
}

variable "worker_instance_type" {
  type        = string
  description = "Instance type for worker nodes"
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes"
}

