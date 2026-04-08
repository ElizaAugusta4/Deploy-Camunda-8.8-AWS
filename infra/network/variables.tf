variable "aws_region" {
  description = "AWS region for network resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "deploy-camunda-88-aws"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.20.2.0/24"
}

variable "tags" {
  description = "Common tags for network resources"
  type        = map(string)
  default = {
    Project     = "deploy-camunda-8.8"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
