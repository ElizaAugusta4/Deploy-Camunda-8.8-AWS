# Network Stack

This stack creates base network resources for the project:

- VPC
- Public subnet
- Private subnet
- Internet Gateway
- Route tables and associations

This phase intentionally does not create NAT Gateway to keep initial cost lower.

## Usage

```powershell
$env:AWS_PROFILE = "conta-014936670405"
terraform init
terraform validate
terraform plan
```

## Backend

The stack uses remote backend in S3 with lock in DynamoDB:

- bucket: deploy-camunda-88-aws-tfstate-014936670405-us-east-1
- key: network/terraform.tfstate
- dynamodb_table: deploy-camunda-88-aws-terraform-lock
