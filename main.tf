# Provider configurations
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-5-terraform-states"
  table_name  = "terraform-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "lesson-5-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

module "eks" {
  source         = "./modules/eks"
  cluster_name   = "lesson-7-eks"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  instance_types = ["t3.medium"]
  desired_size   = 2
  max_size       = 6
  min_size       = 1

  depends_on = [module.vpc, module.ecr]
}

# Kubernetes and Helm providers (configured after EKS cluster is created)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  ecr_repository_url     = module.ecr.repository_url
  aws_region             = "eu-central-1"

  depends_on = [module.eks]
}

module "argo_cd" {
  source                 = "./modules/argo_cd"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data

  depends_on = [module.eks]
}

module "rds" {
  source = "./modules/rds"

  # Database configuration
  use_aurora      = false
  db_name         = "lesson5db"
  master_username = "admin"
  master_password = "SecurePassword123!"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Security
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  # High availability
  multi_az = false

  # Backup configuration
  backup_retention_period = 7
  skip_final_snapshot     = true

  # Protection
  deletion_protection = false

  tags = {
    Environment = "lesson-5"
    Project     = "goit-devops"
  }

  depends_on = [module.vpc]
}

