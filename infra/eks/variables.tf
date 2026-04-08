variable "aws_region" {
  description = "AWS region for EKS resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "deploy-camunda-88-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_group_name" {
  description = "Managed node group name"
  type        = string
  default     = "deploy-camunda-88-ng"
}

variable "node_instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "node_subnet_type" {
  description = "Subnet type for worker nodes: public or private"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.node_subnet_type)
    error_message = "node_subnet_type must be either public or private."
  }
}

variable "tags" {
  description = "Common tags for EKS resources"
  type        = map(string)
  default = {
    Project     = "deploy-camunda-8.8"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
