output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "node_group_name" {
  description = "Managed node group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "irsa_alb_controller_role_arn" {
  description = "IAM role ARN for aws-load-balancer-controller service account"
  value       = aws_iam_role.irsa_alb_controller.arn
}

output "irsa_external_dns_role_arn" {
  description = "IAM role ARN for external-dns service account"
  value       = aws_iam_role.irsa_external_dns.arn
}
