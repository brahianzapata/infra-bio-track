terraform {
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
  }
}

locals {
  oidc_host = replace(var.oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "eso" {
  name = "${var.cluster_name}-eso"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eso_read" {
  role = aws_iam_role.eso.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecretVersionIds"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:bio-track/*"
    }]
  })
}

resource "kubernetes_namespace" "bio_track" {
  metadata {
    name   = "bio-track"
    labels = { "app.kubernetes.io/managed-by" = "terraform" }
  }
}

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata   = { name = "aws-secrets-manager" }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth    = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.bio_track]
}

# Annotate ESO ServiceAccount with IRSA role ARN (created by ESO helm, patched here)
resource "kubernetes_annotations" "eso_sa_irsa" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "external-secrets"
    namespace = "external-secrets"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.eso.arn
  }
  depends_on = [kubernetes_namespace.bio_track]
}
