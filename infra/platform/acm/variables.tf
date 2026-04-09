variable "aws_region" {
  description = "AWS region where ACM certificate is requested"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "deploy-camunda-88-aws"
}

variable "domain_name" {
  description = "Primary domain name for certificate"
  type        = string
  default     = "camunda.elizaaugusta.uk"
}

variable "subject_alternative_names" {
  description = "Optional SANs for certificate"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default = {
    Project     = "deploy-camunda-8.8"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
