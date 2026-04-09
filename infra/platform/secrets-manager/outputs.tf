output "secret_names" {
  description = "Names of created secrets in AWS Secrets Manager"
  value       = [for s in aws_secretsmanager_secret.camunda_k8s : s.name]
}

output "secret_arns" {
  description = "ARNs of created secrets in AWS Secrets Manager"
  value       = [for s in aws_secretsmanager_secret.camunda_k8s : s.arn]
}

output "secrets_version_created" {
  description = "True when at least one secret version was created"
  value       = length(aws_secretsmanager_secret_version.camunda_k8s) > 0
}
