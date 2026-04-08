terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "deploy-camunda-88-aws-tfstate-014936670405-us-east-1"
    key            = "network/terraform.tfstate"
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
