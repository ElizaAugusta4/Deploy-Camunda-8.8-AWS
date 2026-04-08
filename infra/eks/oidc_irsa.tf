data "aws_eks_cluster" "current" {
  name = var.cluster_name
}

data "tls_certificate" "eks_oidc" {
  url = data.aws_eks_cluster.current.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.current.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "irsa_alb_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "irsa_alb_controller" {
  name               = "${var.cluster_name}-irsa-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.irsa_alb_assume.json
}

data "aws_iam_policy_document" "irsa_alb_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
      "cognito-idp:DescribeUserPoolClient",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "tag:GetResources",
      "tag:TagResources"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "irsa_alb_controller" {
  name   = "${var.cluster_name}-irsa-alb-controller-policy"
  policy = data.aws_iam_policy_document.irsa_alb_permissions.json
}

resource "aws_iam_role_policy_attachment" "irsa_alb_controller" {
  role       = aws_iam_role.irsa_alb_controller.name
  policy_arn = aws_iam_policy.irsa_alb_controller.arn
}

data "aws_iam_policy_document" "irsa_external_dns_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
  }
}

resource "aws_iam_role" "irsa_external_dns" {
  name               = "${var.cluster_name}-irsa-external-dns"
  assume_role_policy = data.aws_iam_policy_document.irsa_external_dns_assume.json
}

data "aws_iam_policy_document" "irsa_external_dns_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "irsa_external_dns" {
  name   = "${var.cluster_name}-irsa-external-dns-policy"
  policy = data.aws_iam_policy_document.irsa_external_dns_permissions.json
}

resource "aws_iam_role_policy_attachment" "irsa_external_dns" {
  role       = aws_iam_role.irsa_external_dns.name
  policy_arn = aws_iam_policy.irsa_external_dns.arn
}
