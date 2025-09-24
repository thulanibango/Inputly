resource "kubernetes_namespace" "monitoring" {
  metadata { name = var.monitoring_namespace }
}

resource "helm_release" "kps" {
  name       = var.prometheus_release_name
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.3.2"

  values = [
    yamlencode({
      grafana = {
        adminPassword = var.grafana_admin_password
        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hosts = [ var.grafana_host ]
          annotations = {
            # Add extra annotations if needed (auth, TLS, etc.)
          }
        }
        service = {
          type = "ClusterIP"
        }
      }
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector = {
            matchLabels = {
              release = var.prometheus_release_name
            }
          }
        }
      }
    })
  ]
}
