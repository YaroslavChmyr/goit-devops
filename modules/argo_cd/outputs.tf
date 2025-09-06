output "argocd_url" {
  description = "Argo CD URL"
  value       = "http://argocd-server.${var.namespace}.svc.cluster.local:${var.server_service_port}"
  depends_on  = [helm_release.argocd]
}

output "admin_password" {
  description = "Argo CD admin password"
  value       = var.admin_password
  sensitive   = true
}

output "namespace" {
  description = "Argo CD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

