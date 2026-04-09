terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "camunda_k8s" {
  for_each = var.k8s_secrets_json_map

  name                    = "${var.secret_name_prefix}/${each.key}"
  description             = "Kubernetes secret ${each.key} imported from kind-camunda-test"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    {
      Project   = "camunda"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "camunda_k8s" {
  for_each = var.k8s_secrets_json_map

  secret_id     = aws_secretsmanager_secret.camunda_k8s[each.key].id
  secret_string = each.value
}
