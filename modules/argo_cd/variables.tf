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

variable "name" {
  description = "Name for the Argo CD release"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the Argo CD Helm chart"
  type        = string
  default     = "5.51.6"
}

variable "server_service_type" {
  description = "Type of Kubernetes service for Argo CD server"
  type        = string
  default     = "LoadBalancer"
}

variable "server_service_port" {
  description = "Port for Argo CD server service"
  type        = number
  default     = 80
}

variable "admin_password" {
  description = "Argo CD admin password"
  type        = string
  default     = "admin123"
}

variable "applications" {
  description = "List of Argo CD applications to create"
  type = list(object({
    name      = string
    namespace = string
    project   = string
    source = object({
      repoURL        = string
      targetRevision = string
      path           = string
      helm = optional(object({
        valueFiles = list(string)
      }))
    })
    destination = object({
      server    = string
      namespace = string
    })
    syncPolicy = optional(object({
      automated = optional(object({
        prune    = bool
        selfHeal = bool
      }))
      syncOptions = optional(list(string))
    }))
  }))
  default = []
}

variable "repositories" {
  description = "List of Argo CD repositories to create"
  type = list(object({
    name          = string
    namespace     = string
    type          = string
    url           = string
    username      = optional(string)
    password      = optional(string)
    sshPrivateKey = optional(string)
    insecure      = optional(bool)
    enableLfs     = optional(bool)
  }))
  default = []
}

