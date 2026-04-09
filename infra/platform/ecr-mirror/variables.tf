variable "aws_region" {
  description = "AWS region where ECR repositories will be created"
  type        = string
  default     = "us-east-1"
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for ECR repositories"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "force_repush" {
  description = "Change to true/false to force local-exec re-run for image push"
  type        = bool
  default     = false
}

variable "images" {
  description = "List of images to mirror into ECR"
  type = list(object({
    source_image      = string
    target_repository = string
    target_tag        = string
  }))
}

variable "tags" {
  description = "Common tags for ECR repositories"
  type        = map(string)
  default = {
    Project     = "deploy-camunda-8.8"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "eliza"
  }
}
