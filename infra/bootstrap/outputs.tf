output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "backend_config_example" {
  description = "Backend configuration example for other Terraform stacks"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "REPLACE_ME/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = true
  }
}
