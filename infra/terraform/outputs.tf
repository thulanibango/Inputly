output "namespace" {
  value = kubernetes_namespace.ns.metadata[0].name
}

output "ingress_host" {
  value = var.host
}
