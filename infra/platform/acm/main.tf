terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "deploy-camunda-88-aws-tfstate-014936670405-us-east-1"
    key            = "platform/acm/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "deploy-camunda-88-aws-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

resource "aws_acm_certificate" "camunda" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm"
  }
}

locals {
  dns_validation_records = [
    for dvo in aws_acm_certificate.camunda.domain_validation_options : {
      domain_name = dvo.domain_name
      name        = dvo.resource_record_name
      type        = dvo.resource_record_type
      value       = dvo.resource_record_value
    }
  ]
}
