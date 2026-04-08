# EKS Stack

This stack creates an Amazon EKS cluster and one managed node group.

## Cost and architecture note

- This stack increases cost significantly compared to network/bootstrap.
- Default configuration uses worker nodes in public subnets to avoid NAT requirement in this phase.
- For production, prefer private nodes plus NAT Gateway or VPC endpoints.

## Usage

```powershell
$env:AWS_PROFILE = "conta-014936670405"
terraform init
terraform validate
terraform plan
```

## Backend

- bucket: deploy-camunda-88-aws-tfstate-014936670405-us-east-1
- key: eks/terraform.tfstate
- dynamodb_table: deploy-camunda-88-aws-terraform-lock
