# ------------------------
# Data sources
# ------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# ------------------------
# Harbor module
# ------------------------
module "harbor" {
  source = "./modules/harbor"

  ami_id           = data.aws_ami.ubuntu.id
  vpc_id           = data.aws_vpc.default.id
  key_name         = var.key_name
  instance_type    = var.instance_type
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# ------------------------
# Kubernetes cluster module
# ------------------------
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  ami_id                = data.aws_ami.ubuntu.id
  vpc_id                = data.aws_vpc.default.id
  key_name              = var.key_name
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  control_instance_type = var.control_instance_type
  worker_instance_type  = var.worker_instance_type
  worker_count          = var.worker_count
}

