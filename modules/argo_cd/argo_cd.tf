resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  values = [
    templatefile("${path.module}/values.yaml", {
      server_service_type = var.server_service_type
      server_service_port = var.server_service_port
      admin_password      = var.admin_password
    })
  ]

  create_namespace = true
}

resource "helm_release" "argo_apps" {
  count            = length(var.applications) > 0 ? 1 : 0
  name             = "${var.name}-apps"
  chart            = "${path.module}/charts"
  namespace        = var.namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/charts/values.yaml", {
      applications = var.applications
      repositories = var.repositories
    })
  ]

  depends_on = [helm_release.argocd]
}

