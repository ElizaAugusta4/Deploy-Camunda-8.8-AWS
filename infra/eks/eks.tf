data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "deploy-camunda-88-aws-tfstate-014936670405-us-east-1"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  node_subnet_ids = var.node_subnet_type == "private" ? data.terraform_remote_state.network.outputs.private_subnet_ids : data.terraform_remote_state.network.outputs.public_subnet_ids
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(data.terraform_remote_state.network.outputs.public_subnet_ids, data.terraform_remote_state.network.outputs.private_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = local.node_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker_policy,
    aws_iam_role_policy_attachment.eks_nodes_cni_policy,
    aws_iam_role_policy_attachment.eks_nodes_ecr_policy
  ]
}
