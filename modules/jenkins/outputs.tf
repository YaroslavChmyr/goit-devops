output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://jenkins.${var.namespace}.svc.cluster.local:${var.service_port}"
  depends_on  = [helm_release.jenkins]
}

output "admin_password" {
  description = "Jenkins admin password"
  value       = var.admin_password
  sensitive   = true
}

output "admin_user" {
  description = "Jenkins admin username"
  value       = var.admin_user
}

output "namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

