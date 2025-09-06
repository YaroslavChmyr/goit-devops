variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Version of the Jenkins Helm chart"
  type        = string
  default     = "4.6.0"
}

variable "replica_count" {
  description = "Number of Jenkins replicas"
  type        = number
  default     = 1
}

variable "resources" {
  description = "Resource requests and limits for Jenkins"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

variable "service_type" {
  description = "Type of Kubernetes service for Jenkins"
  type        = string
  default     = "LoadBalancer"
}

variable "service_port" {
  description = "Port for Jenkins service"
  type        = number
  default     = 8080
}

variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  default     = "admin123"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for storing Docker images"
  type        = string
}

