resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

# RBAC will be managed by Helm chart

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_user         = var.admin_user
      admin_password     = var.admin_password
      service_type       = var.service_type
      service_port       = var.service_port
      resources          = var.resources
      replica_count      = var.replica_count
      aws_region         = var.aws_region
      ecr_repository_url = var.ecr_repository_url
    })
  ]

  depends_on = [
    kubernetes_namespace.jenkins
  ]
}

