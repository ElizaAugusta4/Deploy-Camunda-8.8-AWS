variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used in naming"
  type        = string
  default     = "deploy-camunda-88-aws"
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
