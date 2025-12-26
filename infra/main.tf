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
# Harbor Module
# ----------------------------
module "harbor" {
  source = "./modules/harbor"

  ami_id        = data.aws_ami.ubuntu.id
  vpc_id        = data.aws_vpc.default.id
  key_name      = var.key_name
  instance_type = var.instance_type

  # ✅ auto-uses your current public IP
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
# Data sources
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
