resource "kubernetes_namespace" "ns" {
  metadata { name = var.namespace }
}

resource "helm_release" "inputly_api" {
  name       = "inputly-api"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  chart      = "${path.module}/../../deploy/helm/inputly-api"
  version    = "0.1.0"

  values = [
    yamlencode({
      image = {
        repository = var.api_image_repository
        tag        = var.api_image_tag
        pullPolicy = "IfNotPresent"
      }
      env = {
        NODE_ENV = "production"
        PORT     = "3000"
      }
      secrets = {
        JWT_SECRET   = var.jwt_secret
        DATABASE_URL = var.database_url
      }
      service = {
        name = "inputly-api"
        type = "ClusterIP"
        port = 3000
      }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
      replicas = 1
      probes = {
        liveness  = { path = "/health", initialDelaySeconds = 5, periodSeconds = 10 }
        readiness = { path = "/health", initialDelaySeconds = 3, periodSeconds = 5 }
      }
    })
  ]
}

resource "helm_release" "inputly_frontend" {
  name       = "inputly-frontend"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  chart      = "${path.module}/../../deploy/helm/inputly-frontend"
  version    = "0.1.0"

  values = [
    yamlencode({
      image = {
        repository = var.frontend_image_repository
        tag        = var.frontend_image_tag
        pullPolicy = "IfNotPresent"
      }
      service = {
        name = "inputly-frontend"
        type = "ClusterIP"
        port = 80
      }
      replicas = 1
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    })
  ]
}

resource "helm_release" "inputly_ingress" {
  name       = "inputly-ingress"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  chart      = "${path.module}/../../deploy/helm/inputly-ingress"
  version    = "0.1.0"

  values = [
    yamlencode({
      ingress = {
        enabled   = true
        className = "nginx"
        host      = var.host
        annotations = {}
      }
      backend = {
        serviceName = "inputly-api"
        servicePort = 3000
      }
      frontend = {
        serviceName = "inputly-frontend"
        servicePort = 80
      }
    })
  ]
}
