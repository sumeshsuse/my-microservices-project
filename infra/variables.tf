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
