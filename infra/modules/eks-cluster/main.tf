terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_availability_zones" "available" {}

locals {
  # keep it simple and cheaper: 2 AZs is enough for labs
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # subnet tags required by EKS + AWS Load Balancers
  public_subnet_tags = merge(
  {
    "kubernetes.io/role/elb" = "1"
  },
  {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  )

  private_subnet_tags = merge(
  {
    "kubernetes.io/role/internal-elb" = "1"
  },
  {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  # ✅ IMPORTANT: keep subnets inside the VPC CIDR
  # If your var.vpc_cidr is 10.50.0.0/16, these are fine.
  # If you change vpc_cidr later, update subnets accordingly.
  public_subnets  = ["10.50.0.0/24", "10.50.1.0/24"]
  private_subnets = ["10.50.10.0/24", "10.50.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # ✅ Avoid issues with default-* resources (common plan/apply failures)
  manage_default_route_table    = false
  manage_default_network_acl    = false
  manage_default_security_group = false

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  # Recommended for public access during labs (you can lock later)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  eks_managed_node_groups = {
    default = {
      # ✅ keep this SHORT (prevents name_prefix length error)
      name = "ng"

      # ✅ Fix for: "expected length of name_prefix..."
      iam_role_use_name_prefix = false

      # if your cluster_name is long, keep this short too (e.g., "eks-ng-role")
      iam_role_name = "${var.cluster_name}-ng-role"

      instance_types = var.node_instance_types

      desired_size = var.node_desired
      min_size     = var.node_min
      max_size     = var.node_max
    }
  }

  tags = var.tags
}
