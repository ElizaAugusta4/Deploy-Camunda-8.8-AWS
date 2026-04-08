# Bootstrap Terraform State

This stack creates the foundational resources to store Terraform state remotely:

- S3 bucket for state file
- DynamoDB table for state lock

## Usage

1. Configure your AWS profile in the shell:

```powershell
$env:AWS_PROFILE = "conta-014936670405"
```

2. (Optional) copy and edit variables:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

3. Init, validate and plan:

```powershell
terraform init
terraform validate
terraform plan
```

4. Apply when ready:

```powershell
terraform apply
```

## Cost note

- S3 and DynamoDB (on-demand with lock table) are usually low cost.
- This is a common and recommended baseline for production IaC.
