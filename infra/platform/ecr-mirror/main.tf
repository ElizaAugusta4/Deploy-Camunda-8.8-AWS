terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "deploy-camunda-88-aws-tfstate-014936670405-us-east-1"
    key            = "platform/ecr-mirror/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "deploy-camunda-88-aws-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  image_map = {
    for image in var.images :
    "${image.target_repository}:${image.target_tag}" => image
  }

  repositories = toset([for image in var.images : image.target_repository])
}

resource "aws_ecr_repository" "mirror" {
  for_each = local.repositories

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.value
  }
}

resource "null_resource" "push_images" {
  for_each = local.image_map

  triggers = {
    source_image      = each.value.source_image
    target_repository = each.value.target_repository
    target_tag        = each.value.target_tag
    force_repush      = tostring(var.force_repush)
  }

  depends_on = [aws_ecr_repository.mirror]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $region = '${var.aws_region}'
      $accountId = '${data.aws_caller_identity.current.account_id}'
      $registry = $accountId + '.dkr.ecr.' + $region + '.amazonaws.com'

      $token = (aws ecr get-authorization-token --region $region --query "authorizationData[0].authorizationToken" --output text).Trim()
      $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($token))
      $password = $decoded.Split(':', 2)[1]

      docker login --username AWS --password $password $registry | Out-Null

      $src = '${each.value.source_image}'
      $dstRepo = '${each.value.target_repository}'
      $dstTag = '${each.value.target_tag}'
      $dstImage = $registry + '/' + $dstRepo + ':' + $dstTag

      Write-Host ('PULL=' + $src)
      docker pull $src | Out-Null

      Write-Host ('PUSH=' + $dstImage)
      docker tag $src $dstImage
      docker push $dstImage | Out-Null
    EOT
  }
}

import {
  to = aws_ecr_repository.mirror["camunda-mirror/camunda/camunda"]
  id = "camunda-mirror/camunda/camunda"
}

import {
  to = aws_ecr_repository.mirror["camunda-mirror/camunda/console"]
  id = "camunda-mirror/camunda/console"
}

import {
  to = aws_ecr_repository.mirror["camunda-mirror/camunda/connectors-bundle"]
  id = "camunda-mirror/camunda/connectors-bundle"
}
