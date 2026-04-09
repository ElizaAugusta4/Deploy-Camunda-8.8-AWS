# Deploy Camunda 8.8 AWS

## Requisitos

* AWS Cli instalado
* Helm 4.* 

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
-> Instalacao do addon aws-ebs-csi-driver no cluster EKS.
-> Configuracao de permissao IAM para o EBS CSI (AmazonEBSCSIDriverPolicy) com trust OIDC/IRSA.
-> Definicao da StorageClass gp2 como default e validacao de PVCs em Bound.
-> Criacao da stack de ACM em infra/platform/acm com backend remoto (S3 + DynamoDB lock).
-> Execucao de terraform fmt, init, validate e plan da stack de ACM.
-> Execucao de terraform apply da stack de ACM com certificado criado em us-east-1.
-> Criacao do registro CNAME de validacao DNS no Cloudflare (DNS only).
-> Validacao do CNAME com nslookup e emissao do certificado no ACM (status ISSUED).
-> Mapeamento das secrets obrigatorias do release Camunda no kind-camunda-test (camunda-credentials e web-modeler-credential).
-> Criacao da stack de Secrets Manager em infra/platform/secrets-manager.
-> Execucao de terraform apply da stack de Secrets Manager com carga das secrets obrigatorias no AWS Secrets Manager.
-> Criacao da stack de espelhamento de imagens em infra/platform/ecr-mirror.
-> Mapeamento das imagens em uso no namespace camunda para envio ao ECR.
-> Configuracao do Terraform para criacao/import de repositorios ECR e push das imagens via local-exec (docker pull/tag/push).
-> Preparacao de apps/camunda com values customizado para EKS (chart 13.6.0) e scripts de deploy.
-> Reducao de requests/limits e desabilitacao de componentes opcionais (console, connectors, optimize e web modeler) para perfil de menor custo.
-> Ajuste de estabilidade de Elasticsearch/Zeebe sem aumento de nodegroup.
-> Validacao final do namespace camunda com pods core em Running (elasticsearch, identity, keycloak, zeebe e bancos).

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

### 6) infra/platform/acm (certificado TLS)

Objetivo: criar certificado ACM para o dominio da aplicacao e validar por DNS no Cloudflare.

1. terraform fmt
2. terraform init
3. terraform validate
4. terraform plan
5. terraform apply

Resultado esperado:

- Certificado criado no ACM (regiao us-east-1)
- Output com o CNAME de validacao DNS
- Status inicial: PENDING_VALIDATION
- Status final: ISSUED (validacao DNS concluida com SUCCESS)

Depois do apply (manual no Cloudflare):

1. Criar o CNAME retornado pelo Terraform em DNS > Records
2. Manter Proxy status como DNS only
3. Aguardar propagacao e revalidar no ACM

### 7) infra/platform/secrets-manager (secrets obrigatorias do Camunda)

Objetivo: enviar para o AWS Secrets Manager as secrets obrigatorias usadas no release Camunda que roda no kind-camunda-test.

Secrets mapeadas como obrigatorias no values efetivo do release:

- camunda-credentials
- web-modeler-credential

Fluxo executado:

1. terraform init
2. terraform validate
3. Ler secrets do cluster kind-camunda-test (namespace camunda)
4. Popular TF_VAR_k8s_secrets_json_map com os payloads JSON das secrets obrigatorias
5. terraform plan
6. terraform apply

Resultado esperado:

- Secrets criadas no AWS:
	- camunda/k8s/camunda-credentials
	- camunda/k8s/web-modeler-credential
- Versao de secret criada para cada item

### 8) infra/platform/ecr-mirror (repositorios ECR e push de imagens)

Objetivo: criar repositorios no ECR e espelhar as imagens do Camunda e dependencias que estao em uso no cluster local.

Fluxo executado:

1. terraform init
2. terraform validate
3. Preencher images em terraform.tfvars com source_image, target_repository e target_tag
4. terraform plan
5. terraform apply

Observacoes importantes:

- A stack usa null_resource + local-exec para executar docker login/pull/tag/push via Terraform
- Para repositorios ECR ja existentes, foram adicionados blocos import para conciliacao no state
- Prefixo adotado para mirror no ECR: camunda-mirror/

Resultado esperado:

- Repositorios ECR criados/conciliados para todas as imagens mapeadas
- Imagens publicadas no ECR com as tags definidas em terraform.tfvars

### 9) apps/camunda (estabilizacao dos pods)

Objetivo: aplicar um perfil de menor consumo para manter o ambiente funcional sem ampliar quantidade de nodes.

Fluxo executado:

1. Ajuste do arquivo apps/camunda/values-13.6.0.yaml
2. Desabilitacao de componentes opcionais para reduzir consumo:
	- console
	- connectors
	- optimize
	- webModeler
	- webModelerPostgresql
3. Reducao de requests dos componentes core (identity, keycloak, orchestration, elasticsearch)
4. Ajuste de estabilidade do Elasticsearch (heap e limites) mantendo request baixo
5. helm upgrade --install com o values ajustado
6. Validacao com kubectl get pods -n camunda
7. Validacao de storage dinamico com addon aws-ebs-csi-driver e PVCs Bound (Zeebe e Elasticsearch)

Resultado esperado:

- Pods core do Camunda em Running no namespace camunda
- Ambiente estabilizado sem aumento de nodegroup
- Provisionamento dinamico de volumes funcionando via ebs.csi.aws.com

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

1. Adicionar repositorios Helm:

- helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
- helm repo add jetstack https://charts.jetstack.io
- helm repo add eks https://aws.github.io/eks-charts
- helm repo update

2. Criar namespace e service account:

- kubectl create namespace cert-manager 
- kubectl create serviceaccount aws-load-balancer-controller -n kube-system 
- kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system eks.amazonaws.com/role-arn=$albRole --overwrite

3. Instalar addons:

Variáveis que precisam ser preenchidas: 

  $ACCOUNT_ID = id_account
  $Cluster = cluster-name
  $vpc = vpcid
  $albRole = "arn:aws:iam::<ACCOUNT_ID>:role/deploy-camunda-88-eks-irsa-alb-controller"


- helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
- helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --set crds.enabled=true
- helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=$vpc


Comandos de verificacao dos addons:

- kubectl -n kube-system rollout status deployment/metrics-server
- kubectl -n kube-system rollout status deployment/aws-load-balancer-controller
- kubectl -n cert-manager rollout status deployment/cert-manager
- kubectl -n cert-manager rollout status deployment/cert-manager-webhook
- kubectl -n cert-manager rollout status deployment/cert-manager-cainjector

Comandos de verificacao EBS CSI / Storage:

- aws eks describe-addon --region us-east-1 --cluster-name deploy-camunda-88-eks --addon-name aws-ebs-csi-driver --query addon.status
- kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-ebs-csi-driver
- kubectl get storageclass
- kubectl get pvc -n camunda

Comandos de verificacao ACM/DNS:

- aws acm describe-certificate --region us-east-1 --certificate-arn <CERTIFICATE_ARN>
- nslookup -type=CNAME <NOME_DO_CNAME_DE_VALIDACAO>

Comandos de verificacao Secrets Manager:

- aws secretsmanager list-secrets --region us-east-1 --query "SecretList[?starts_with(Name, 'camunda/k8s/')].Name"
- aws secretsmanager get-secret-value --region us-east-1 --secret-id camunda/k8s/camunda-credentials --query SecretString --output text
- aws secretsmanager get-secret-value --region us-east-1 --secret-id camunda/k8s/web-modeler-credential --query SecretString --output text

Comandos de verificacao ECR:

- aws ecr describe-repositories --region us-east-1 --query "repositories[?starts_with(repositoryName, 'camunda-mirror/')].repositoryName"
- aws ecr describe-images --region us-east-1 --repository-name camunda-mirror/camunda/camunda --query "length(imageDetails)"
- aws ecr describe-images --region us-east-1 --repository-name camunda-mirror/camunda/connectors-bundle --query "length(imageDetails)"
- aws ecr describe-images --region us-east-1 --repository-name camunda-mirror/camunda/console --query "length(imageDetails)"

Nota:

- O fluxo recomendado e sempre: terraform init -> terraform validate -> terraform plan -> terraform apply

## Proximos passos

1. Finalizar o envio de todas as imagens faltantes para o ECR.
2. Preparar values para o EKS apontando para imagens do ECR e secrets da AWS.
3. Instalar o chart Camunda no cluster EKS e validar pods/servicos.
4. Configurar Ingress + Load Balancer + DNS para acesso HTTPS.