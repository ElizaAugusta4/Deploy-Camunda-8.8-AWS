param(
  [string]$AwsProfile = "conta-014936670405",
  [string]$EksContext = "arn:aws:eks:us-east-1:014936670405:cluster/deploy-camunda-88-eks",
  [string]$Namespace = "camunda",
  [string]$ReleaseName = "camunda",
  [string]$ChartVersion = "13.6.0",
  [string]$ValuesFile = "values-13.6.0.yaml"
)

$ErrorActionPreference = "Stop"

$env:AWS_PROFILE = $AwsProfile
kubectl config use-context $EksContext | Out-Null

helm repo add camunda https://helm.camunda.io | Out-Null
helm repo update | Out-Null

helm upgrade --install $ReleaseName camunda/camunda-platform `
  --version $ChartVersion `
  -f $ValuesFile `
  -n $Namespace `
  --create-namespace `
  --timeout 30m

kubectl get pods -n $Namespace | Out-String
