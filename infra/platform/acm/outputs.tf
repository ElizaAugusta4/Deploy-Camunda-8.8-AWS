output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.camunda.arn
}

output "certificate_status" {
  description = "Current ACM certificate status"
  value       = aws_acm_certificate.camunda.status
}

output "dns_validation_records" {
  description = "Create these CNAME records in Cloudflare to validate the certificate"
  value       = local.dns_validation_records
}
