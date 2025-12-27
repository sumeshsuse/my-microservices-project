variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Harbor instance"
  default     = "t3.medium"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into EC2 instances (your public IP /32)"
}

variable "allowed_client_cidr" {
  type        = string
  description = "CIDR allowed to access Harbor registry probe on 443 (your public IP /32)"
}

variable "k8s_control_instance_type" {
  type        = string
  description = "Instance type for Kubernetes control plane"
  default     = "t3.medium"
}

variable "k8s_worker_instance_type" {
  type        = string
  description = "Instance type for Kubernetes worker nodes"
  default     = "t3.medium"
}

variable "k8s_worker_count" {
  type        = number
  description = "Number of Kubernetes worker nodes"
  default     = 2
}
