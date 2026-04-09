output "ecr_repository_names" {
  description = "ECR repository names created for mirrored images"
  value       = [for repo in aws_ecr_repository.mirror : repo.name]
}

output "ecr_repository_urls" {
  description = "ECR repository URLs created for mirrored images"
  value       = [for repo in aws_ecr_repository.mirror : repo.repository_url]
}

output "mirrored_images" {
  description = "Destination image references mirrored to ECR"
  value = [
    for image in var.images :
    "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${image.target_repository}:${image.target_tag}"
  ]
}
