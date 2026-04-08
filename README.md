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
-> Criacao de orcamento (AWS Budget) para controle de custos.
-> Evolucao da stack de rede para EKS-ready (2 AZs, 2 subnets publicas e 2 privadas).
-> Adicao das tags de subnets para Kubernetes/ALB (kubernetes.io/role/elb e kubernetes.io/role/internal-elb).
-> Execucao de terraform plan da rede EKS-ready.
-> Execucao de terraform apply da rede EKS-ready (4 recursos criados, 2 atualizados).
-> Validacao final da rede EKS-ready com terraform plan sem mudancas (No changes).
-> Confirmacao de que nao ha NAT Gateway criado na VPC.
-> Criacao da stack de EKS em infra/eks com backend remoto (S3 + DynamoDB lock).
-> Execucao de terraform fmt, init, validate e plan da stack de EKS.
-> Planejamento do EKS no modo de menor custo inicial (node group em subnets publicas, sem NAT).
-> Commit das alteracoes de rede EKS-ready + stack EKS no repositorio.
-> Resolucao de lock do Terraform state do modulo EKS e conciliacao de recursos via import.
-> Execucao de terraform apply da stack de EKS com node group criado com sucesso.
-> Validacao do cluster EKS ativo com node Ready e kube-system em Running.
-> Configuracao de OIDC provider do cluster para autenticacao federada.
-> Criacao das roles IRSA para aws-load-balancer-controller e external-dns.
-> Execucao de terraform apply da etapa OIDC/IRSA sem destruicao de recursos.
-> Atualizacao do kubeconfig e validacao do cluster EKS com node group ativo.
-> Instalacao do metrics-server via Helm no namespace kube-system.
-> Instalacao do cert-manager via Helm no namespace cert-manager.
-> Instalacao do AWS Load Balancer Controller via Helm com ServiceAccount anotada por IRSA.
-> Validacao dos deployments e pods dos addons em estado Running.

## Execucao detalhada por pasta (ordem correta)

Antes de rodar Terraform em qualquer pasta:

1. Definir profile AWS na sessao:
	 - $env:AWS_PROFILE="conta-id"

### 1) infra/bootstrap

Objetivo: criar backend remoto do Terraform (S3 + DynamoDB lock).

1. terraform init
2. terraform validate
3. terraform plan
4. terraform apply

Resultado esperado:

- Bucket S3 de state criado
- Tabela DynamoDB de lock criada

### 2) infra/network (primeira execucao)

Objetivo: criar rede base.

1. terraform init
2. terraform validate
3. terraform plan
4. terraform apply

Resultado esperado:

- VPC
- Subnet publica e privada
- IGW
- Route tables e associacoes

### 3) infra/network (evolucao para EKS-ready)

Objetivo: preparar rede para EKS em 2 AZs.

1. terraform fmt
2. terraform validate
3. terraform plan
4. terraform apply
5. terraform plan (confirmacao final sem mudancas)

Resultado esperado:

- 2 subnets publicas + 2 subnets privadas
- Tags kubernetes.io/role/elb e kubernetes.io/role/internal-elb
- Tags kubernetes.io/cluster/deploy-camunda-88-eks

### 4) infra/eks (criacao do cluster)

Objetivo: subir cluster EKS e node group.

1. terraform init
2. terraform validate
3. terraform plan
4. terraform apply

Observacoes importantes desta etapa:

- Foi necessario tratar lock de state (force-unlock).
- Foi necessario importar recursos ja existentes para o state:
	- aws_iam_role.eks_cluster
	- aws_iam_role.eks_nodes
	- aws_eks_cluster.main
- Depois do import, foi executado novamente:
	1. terraform plan
	2. terraform apply

### 5) infra/eks (OIDC/IRSA)

Objetivo: preparar identidade para addons.

1. terraform fmt
2. terraform init
3. terraform validate
4. terraform plan
5. terraform apply

Resultado esperado:

- aws_iam_openid_connect_provider criado
- Roles IRSA criadas para:
	- aws-load-balancer-controller
	- external-dns

## Comandos manuais executados (fora do Terraform)

Validacoes AWS/Kubernetes:

- aws sts get-caller-identity --profile conta-id
- aws eks list-clusters --region us-east-1
- aws eks describe-cluster --region us-east-1 --name deploy-camunda-88-eks
- aws eks update-kubeconfig --region us-east-1 --name deploy-camunda-88-eks --profile conta-id
- kubectl get nodes -o wide
- kubectl get pods -A

Instalacao de addons via Helm:

- metrics-server
- cert-manager
- aws-load-balancer-controller (com ServiceAccount anotada para IRSA)

Comandos de verificacao dos addons:

- kubectl -n kube-system rollout status deployment/metrics-server
- kubectl -n kube-system rollout status deployment/aws-load-balancer-controller
- kubectl -n cert-manager rollout status deployment/cert-manager
- kubectl -n cert-manager rollout status deployment/cert-manager-webhook
- kubectl -n cert-manager rollout status deployment/cert-manager-cainjector

Nota:

- O fluxo recomendado e sempre: terraform init -> terraform validate -> terraform plan -> terraform apply
