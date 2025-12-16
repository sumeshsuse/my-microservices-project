variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

# Harbor EC2 instance type
variable "instance_type" {
  description = "Instance type for Harbor EC2"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into instances"
  type        = string
}

variable "allowed_client_cidr" {
  description = "CIDR allowed for Docker HTTPS probe on 443 (your public IP /32)"
  type        = string
}

# ----------------------------
# K8s cluster variables
# ----------------------------
variable "k8s_control_instance_type" {
  description = "Instance type for Kubernetes control plane"
  type        = string
}

variable "k8s_worker_instance_type" {
  description = "Instance type for Kubernetes worker nodes"
  type        = string
}

variable "k8s_worker_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
}
