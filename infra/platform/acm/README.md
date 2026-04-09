# ACM Certificate (Cloudflare DNS validation)

This stack requests an ACM certificate and outputs DNS CNAME records for manual validation in Cloudflare.

## Steps

1. Set AWS profile in terminal:

```powershell
$env:AWS_PROFILE = "conta-014936670405"
```

2. Run Terraform:

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

3. After apply, read the output `dns_validation_records`.
4. Create those CNAME records in Cloudflare (DNS only).
5. Wait a few minutes and check certificate status in ACM.

## Notes

- Use ACM in `us-east-1` when the certificate will be attached to ALB in this region.
- This stack does not auto-create Cloudflare records.
