terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# ----------------------------
# Find your CURRENT public IP (Mac)
# ----------------------------
data "http" "myip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_public_ip_cidr = "${chomp(data.http.myip.response_body)}/32"
}

# ----------------------------
# Data sources (Default VPC + Ubuntu AMI)
# ----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# ----------------------------
# Harbor Module (EC2)
# ----------------------------
module "harbor" {
  source = "./modules/harbor"

  ami_id        = data.aws_ami.ubuntu.id
  vpc_id        = data.aws_vpc.default.id
  key_name      = var.key_name
  instance_type = var.instance_type

  allowed_ssh_cidr    = local.my_public_ip_cidr
  allowed_client_cidr = local.my_public_ip_cidr
}

# ----------------------------
# Kubernetes Cluster Module (EC2 kubeadm)
# ----------------------------
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  ami_id           = data.aws_ami.ubuntu.id
  vpc_id           = data.aws_vpc.default.id
  key_name         = var.key_name
  allowed_ssh_cidr = local.my_public_ip_cidr

  control_instance_type = var.k8s_control_instance_type
  worker_instance_type  = var.k8s_worker_instance_type
  worker_count          = var.k8s_worker_count
}

# ----------------------------
# ✅ NEW: EKS Cluster Module (optional)
# ----------------------------
module "eks_cluster" {
  source = "./modules/eks-cluster"
  count  = var.enable_eks ? 1 : 0

  cluster_name       = var.eks_cluster_name
  cluster_version    = var.eks_cluster_version
  node_instance_types = var.eks_node_instance_types
  node_desired       = var.eks_node_desired
  node_min           = var.eks_node_min
  node_max           = var.eks_node_max

  tags = {
    Project = "my-microservices-project"
    Owner   = "sumesh"
  }
}
