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
