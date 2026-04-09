# ECR Mirror (Terraform)

This stack mirrors Camunda images from Docker Hub to AWS ECR using Terraform.

## What it does

- Creates ECR repositories listed in `terraform.tfvars`
- Pushes each source image to ECR during `terraform apply`

## Usage (PowerShell)

```powershell
$env:AWS_PROFILE = "conta-014936670405"
terraform init
terraform validate
terraform plan
terraform apply
```

## Notes

- Docker must be running locally.
- AWS CLI must be authenticated.
- To force image re-push, change `force_repush` value in `terraform.tfvars`.
