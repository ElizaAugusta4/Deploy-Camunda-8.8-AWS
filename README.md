# Deploy Camunda 8.8 AWS

## Comandos usados no projeto

Configurar acesso a conta da AWS:

aws configure --profile xxxxxx

Validar acesso a conta:

aws sts get-caller-identity --profile xxxxxx

Terraform:

terraform fmt -check
terraform init
terraform validate
terraform plan

## Etapas realizadas ate agora

-> Criacao de usuario IAM com permissoes.
-> Criacao de access key para esse usuario.
-> Login na conta via AWS CLI com o profile.
-> Estrutura inicial do repositorio no GitHub.
-> Criacao do stack de bootstrap do state remoto (S3 + DynamoDB lock) com encryption AES256.
-> Execucao de init, validate e plan no bootstrap com o profile correto.
-> Ajuste no gitignore para versionar o arquivo .terraform.lock.hcl (boa pratica).
-> Execucao de terraform apply no bootstrap (S3 + DynamoDB criados com sucesso).
-> Criacao da stack de rede em infra/network com backend remoto (S3 + DynamoDB lock).
-> Execucao de init, validate e plan da stack de rede.
-> Execucao de terraform apply da stack de rede (VPC, subnets, IGW e route tables).
-> Validacao final com terraform plan sem mudancas (No changes).
