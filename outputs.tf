output "s3_bucket" {
  value = module.s3_backend.s3_bucket_name
}

output "dynamodb_table" {
  value = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repo_url" {
  value = module.ecr.repository_url
}

# EKS Cluster outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the cluster"
  value       = module.eks.kubeconfig_command
}

# Jenkins outputs
output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = module.jenkins.admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.admin_password
  sensitive   = true
}

# Argo CD outputs
output "argocd_url" {
  description = "Argo CD URL"
  value       = module.argo_cd.argocd_url
}

output "argocd_admin_password" {
  description = "Argo CD admin password"
  value       = module.argo_cd.admin_password
  sensitive   = true
}
