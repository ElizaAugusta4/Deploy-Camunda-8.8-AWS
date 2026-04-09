variable "aws_region" {
  description = "AWS region where the secret will be created"
  type        = string
  default     = "us-east-1"
}

variable "secret_name_prefix" {
  description = "Prefix used in AWS Secrets Manager names"
  type        = string
  default     = "camunda/k8s"
}

variable "recovery_window_in_days" {
  description = "Recovery window for secret deletion (7 to 30 days)"
  type        = number
  default     = 7
}

variable "k8s_secrets_json_map" {
  description = "Map where key is Kubernetes secret name and value is JSON payload"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to the secret"
  type        = map(string)
  default     = {}
}
