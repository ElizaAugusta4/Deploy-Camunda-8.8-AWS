param(
  [string]$AwsProfile = "conta-014936670405",
  [string]$AwsRegion = "us-east-1",
  [string]$EksContext = "arn:aws:eks:us-east-1:014936670405:cluster/deploy-camunda-88-eks",
  [string]$Namespace = "camunda"
)

$ErrorActionPreference = "Stop"

$secretMap = @{
  "camunda/k8s/camunda-credentials"   = "camunda-credentials"
  "camunda/k8s/web-modeler-credential" = "web-modeler-credential"
}

$env:AWS_PROFILE = $AwsProfile

kubectl config use-context $EksContext | Out-Null
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f - | Out-Null

foreach ($awsSecretName in $secretMap.Keys) {
  $k8sSecretName = $secretMap[$awsSecretName]

  $secretString = aws secretsmanager get-secret-value `
    --region $AwsRegion `
    --secret-id $awsSecretName `
    --query SecretString `
    --output text

  $payload = $secretString | ConvertFrom-Json
  $stringData = @{}

  foreach ($prop in $payload.PSObject.Properties) {
    $stringData[$prop.Name] = [string]$prop.Value
  }

  $manifest = @{
    apiVersion = "v1"
    kind       = "Secret"
    metadata   = @{
      name      = $k8sSecretName
      namespace = $Namespace
    }
    type       = "Opaque"
    stringData = $stringData
  }

  $manifestJson = $manifest | ConvertTo-Json -Depth 20
  $manifestJson | kubectl apply -f - | Out-Null

  Write-Output ("SYNCED_SECRET=" + $k8sSecretName)
}

kubectl get secrets -n $Namespace | Out-String
