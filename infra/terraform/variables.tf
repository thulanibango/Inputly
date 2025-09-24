variable "kubeconfig" {
  description = "Path to kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "inputly"
}

variable "api_image_repository" {
  description = "API image repository"
  type        = string
  default     = "inputly"
}

variable "api_image_tag" {
  description = "API image tag"
  type        = string
  default     = "local"
}

variable "frontend_image_repository" {
  description = "Frontend image repository"
  type        = string
  default     = "inputly-frontend"
}

variable "frontend_image_tag" {
  description = "Frontend image tag"
  type        = string
  default     = "local"
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Database connection string"
  type        = string
  sensitive   = true
}

variable "host" {
  description = "Ingress host"
  type        = string
  default     = "inputly.local"
}

variable "monitoring_namespace" {
  description = "Namespace to install monitoring stack (Prometheus/Grafana)"
  type        = string
  default     = "monitoring"
}

variable "grafana_host" {
  description = "Ingress host for Grafana UI"
  type        = string
  default     = "grafana.local"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "prometheus_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  type        = string
  default     = "kube-prometheus-stack"
}
