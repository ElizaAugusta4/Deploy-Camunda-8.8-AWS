# Deploy Camunda 8.8 na AWS (Guia Pratico e Didatico)

## Objetivo
Este documento explica, do zero e em ordem, como foi feito o deploy do Camunda 8.8 na AWS com EKS, Terraform, Helm, ECR, Secrets Manager, ACM e Ingress com ALB.

A ideia e que qualquer pessoa (mesmo sem muita experiencia) consiga entender:
- O que cada etapa faz
- Por que cada etapa existe
- Como executar
- Como validar
- Quais problemas comuns podem aparecer

## Seguranca e Privacidade
Para evitar exposicao de dados sensiveis, este README usa placeholders.
Sempre substitua os valores de exemplo pelos valores reais do seu ambiente.

## Convencao de Placeholders (substituir no seu ambiente)
- xxxxxxx-profile: nome do profile AWS CLI
- xxxxxxx-region: regiao AWS (exemplo: us-east-1)
- xxxxxxx-cluster: nome do cluster EKS
- xxxxxxx-domain: dominio publico usado no Ingress
- xxxxxxx-account-id: ID da conta AWS
- xxxxxxx-vpc-id: ID da VPC
- xxxxxxx-cert-arn: ARN do certificado ACM emitido
- xxxxxxx-alb-dns: DNS do ALB criado pelo Ingress
- xxxxxxx-role-arn: ARN de role IAM/IRSA

## Pre-requisitos
- AWS CLI instalado e autenticado
- Terraform instalado
- kubectl instalado
- Helm instalado
- Docker instalado (para espelhar imagens no ECR)
- Acesso ao Cloudflare (ou provedor DNS equivalente)

## Fluxo Geral do Projeto
1. Criar backend remoto do Terraform (S3 + DynamoDB).
2. Criar rede (VPC/subnets) preparada para EKS.
3. Criar cluster EKS e node group.
4. Configurar OIDC/IRSA e addons do cluster.
5. Garantir storage dinamico (EBS CSI) para PVCs.
6. Criar e validar certificado ACM.
7. Migrar secrets para AWS Secrets Manager.
8. Espelhar imagens no ECR.
9. Fazer deploy do Camunda com values ajustado para custo.
10. Expor via Ingress ALB com HTTPS e DNS publico.

## Etapa 0 - Controle de custo (obrigatorio)
### O que esta etapa faz
Cria um Budget para evitar surpresa de custo.

### Comando/acao
- Criar AWS Budget mensal com limite baixo e alertas.

### Validacao
- Budget criado e ativo no Billing.

## Etapa 1 - Backend remoto do Terraform (infra/bootstrap)
### O que esta etapa faz
Cria:
- Bucket S3 para state
- DynamoDB para lock

Sem isso, o Terraform pode corromper estado em execucoes concorrentes.

### Comandos
- terraform init
- terraform validate
- terraform plan
- terraform apply

### Validacao
- Bucket de state criado
- Tabela de lock criada

## Etapa 2 - Rede base e rede EKS-ready (infra/network)
### O que esta etapa faz
Cria VPC, subnets e rotas.
Depois evolui para topologia pronta para EKS em 2 AZs.

### Comandos
- terraform init
- terraform validate
- terraform plan
- terraform apply

### Validacao
- Subnets publicas e privadas em 2 AZs
- Tags para Kubernetes/ALB aplicadas
- Plan final sem mudancas

## Etapa 3 - Cluster EKS (infra/eks)
### O que esta etapa faz
Cria o cluster EKS e node group.

### Comandos
- terraform init
- terraform validate
- terraform plan
- terraform apply

### Validacao
- Cluster criado
- Nodes em Ready
- Pods de sistema em Running

### Observacao importante
Se houver recursos ja existentes, pode ser necessario import no state antes do apply.

## Etapa 4 - OIDC/IRSA e addons principais
### O que esta etapa faz
- Habilita OIDC provider do cluster
- Cria roles IRSA para addons
- Instala:
  - metrics-server
  - cert-manager
  - aws-load-balancer-controller

### Comandos de referencia
- helm repo add ...
- helm upgrade --install ...
- kubectl rollout status ...

### Validacao
- Deployments dos addons em Running

## Etapa 5 - Storage dinamico com EBS CSI
### O que esta etapa faz
Instala o addon aws-ebs-csi-driver e configura permissoes IAM para provisionar volumes EBS automaticamente.

Sem esta etapa, PVCs de componentes stateful podem ficar em Pending.

### Comandos de validacao
- aws eks describe-addon --region xxxxxxx-region --cluster-name xxxxxxx-cluster --addon-name aws-ebs-csi-driver --query addon.status
- kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-ebs-csi-driver
- kubectl get storageclass
- kubectl get pvc -n camunda

### Validacao esperada
- Addon em Active
- StorageClass padrao definida
- PVCs em Bound

## Etapa 6 - Certificado TLS ACM (infra/platform/acm)
### O que esta etapa faz
Cria certificado TLS no ACM e gera CNAME de validacao DNS.

### Comandos
- terraform init
- terraform validate
- terraform plan
- terraform apply

### Validacao
- Status inicial PENDING_VALIDATION
- Criar CNAME no DNS
- Status final ISSUED

## Etapa 7 - Secrets no AWS Secrets Manager (infra/platform/secrets-manager)
### O que esta etapa faz
Migra secrets obrigatorias do ambiente local para AWS.

### Secrets mapeadas
- camunda-credentials
- web-modeler-credential

### Fluxo
1. Ler secrets do cluster de origem
2. Popular variavel TF com payloads JSON
3. Plan e apply

### Validacao
- Secrets criadas no Secrets Manager
- Secret versions criadas

## Etapa 8 - ECR mirror de imagens (infra/platform/ecr-mirror)
### O que esta etapa faz
Cria repositorios ECR e envia imagens usadas no deploy.

### Como funciona
A stack usa local-exec para docker login/pull/tag/push.

### Validacao
- Repositorios criados/conciliados
- Imagens com tags no ECR

## Etapa 9 - Deploy Camunda com perfil de custo reduzido (apps/camunda)
### O que esta etapa faz
Aplica values customizado para EKS e ajusta recursos para reduzir custo sem quebrar o ambiente.

### Ajustes feitos
- Reducao de requests/limits
- Desabilitacao de componentes opcionais no perfil de baixo custo
- Ajustes de estabilidade para Elasticsearch e Zeebe

### Comando
- helm upgrade --install camunda camunda/camunda-platform --version 13.6.0 -n camunda -f apps/camunda/values-13.6.0.yaml

### Validacao
- Pods core em Running:
  - Elasticsearch
  - Identity
  - Keycloak
  - Zeebe
  - Bancos

## Etapa 10 - Ingress ALB + HTTPS + DNS publico
### O que esta etapa faz
Exposicao publica via ALB com HTTPS, usando certificado ACM.

### Ajustes principais no values
- global.ingress.enabled: true
- global.ingress.className: alb
- global.ingress.host: xxxxxxx-domain
- Anotacoes ALB para:
  - internet-facing
  - target-type ip
  - listeners 80/443
  - redirect HTTP -> HTTPS
  - certificate-arn

### Comandos de validacao
- kubectl get ingress -n camunda -o wide
- kubectl describe ingress camunda-camunda-platform-http -n camunda
- aws elbv2 describe-load-balancers --region xxxxxxx-region
- nslookup xxxxxxx-domain 1.1.1.1
- nslookup xxxxxxx-domain 8.8.8.8

### Resultado esperado
- Ingress reconciliado
- ALB em active
- HTTPS respondendo no dominio

### Persistencia OIDC (importante)
- Manter `global.security.authentication.method` como `oidc`.
- Manter `global.identity.auth.publicIssuerUrl` com dominio publico (`https://camunda.elizaaugusta.uk/auth/realms/camunda-platform`).
- Manter `identity.fullURL` como `https://camunda.elizaaugusta.uk/identity` e `identity.contextPath` como `/identity`.
- Manter `orchestration.security.authentication.method` como `oidc`.
- Manter `orchestration.security.authentication.oidc.redirectUrl` como `https://camunda.elizaaugusta.uk`.
- Referenciar secret OIDC da orchestration:
  - `orchestration.security.authentication.oidc.secret.existingSecret: camunda-orchestration-oidc`
  - `orchestration.security.authentication.oidc.secret.existingSecretKey: identity-orchestration-client-token`
- No ingress customizado (`global.extraManifests`), manter os paths de auth/callback:
  - `/oauth2`
  - `/login`
  - `/sso-callback`

## Problemas reais encontrados (e como resolvemos)
### 1) Pods Pending por falta de recurso
Causa: requests altos para o tipo de node.
Acao: reduzir requests/limits e desabilitar componentes opcionais.

### 2) PVC Pending
Causa: storage dinamico nao configurado corretamente.
Acao: instalar/configurar EBS CSI e ajustar StorageClass padrao.

### 3) DNS local com NXDOMAIN, mesmo com tudo certo na AWS
Causa: resolvedor local (roteador/provedor) sem resolver cadeia completa.
Acao:
- Validar em DNS publico (1.1.1.1 / 8.8.8.8)
- Testar por outra rede/dispositivo
- (Opcional) trocar DNS local para resolvedor publico

## Comandos de verificacao rapida
### Cluster e pods
- kubectl get nodes -o wide
- kubectl get pods -n camunda -o wide
- kubectl get pods -A

### Ingress e ALB
- kubectl get ingress -n camunda -o wide
- kubectl describe ingress camunda-camunda-platform-http -n camunda
- aws elbv2 describe-load-balancers --region xxxxxxx-region --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s-camunda')]"

### DNS e HTTPS
- nslookup xxxxxxx-domain 1.1.1.1
- nslookup xxxxxxx-domain 8.8.8.8
- curl -I https://xxxxxxx-domain/auth/

### Storage
- kubectl get storageclass
- kubectl get pvc -n camunda

## Estado atual (resumo)
- Infra principal criada
- Addons essenciais funcionando
- EBS CSI funcionando
- Camunda core em Running
- Ingress ALB criado com HTTPS
- Dominio publico dependendo apenas de propagacao/qualidade do DNS local de quem acessa

## Boas praticas operacionais
- Sempre executar: terraform init -> terraform validate -> terraform plan -> terraform apply
- Nunca expor valores de secret em README ou log
- Usar placeholders (xxxxxxx) em toda documentacao publica
- Validar DNS em resolvedor publico antes de concluir que e problema da AWS

## Proximos passos
1. Confirmar acesso HTTPS por mais de uma rede/provedor.
2. Registrar endpoint final validado e horario da validacao.
3. Opcional: revisar perfil de custo para manter operacao dentro do orcamento.
