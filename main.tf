######################################
# VPC (EKS-Compatible, Lab Friendly)
######################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-free-tier-vpc"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  enable_nat_gateway        = false
  enable_dns_hostnames      = true
  map_public_ip_on_launch   = true   # 👈 THIS FIXES THE NODE GROUP ERROR
}

######################################
# EKS Cluster (Direct Resource)
######################################
resource "aws_eks_cluster" "this" {
  name     = "eks-free-tier"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.34"

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }

  # ✅ REQUIRED FOR A CLOUD GURU LABS
  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller_policy
  ]
}

######################################
# EKS Managed Node Group
######################################
resource "aws_eks_node_group" "free_tier_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "free-tier-nodes"
  node_role_arn  = aws_iam_role.eks_node_role.arn
  subnet_ids     = module.vpc.public_subnets

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  depends_on = [
    aws_eks_cluster.this
  ]
}
