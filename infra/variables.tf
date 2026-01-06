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
  default     = "" # not used directly now (we auto-detect IP), but kept for compatibility
}

variable "allowed_client_cidr" {
  type        = string
  description = "CIDR allowed to access Harbor registry probe on 443 (your public IP /32)"
  default     = "" # not used directly now (we auto-detect IP), but kept for compatibility
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

# ----------------------------
# ✅ NEW: EKS toggle + settings
# ----------------------------
variable "enable_eks" {
  type        = bool
  description = "Enable EKS cluster creation"
  default     = false
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "my-microservices-eks"
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "eks_node_instance_types" {
  type        = list(string)
  description = "Instance types for EKS managed node group"
  default     = ["t3.medium"]
}

variable "eks_node_desired" {
  type        = number
  description = "Desired node count"
  default     = 1
}

variable "eks_node_min" {
  type        = number
  description = "Minimum node count"
  default     = 1
}

variable "eks_node_max" {
  type        = number
  description = "Maximum node count"
  default     = 2
}
