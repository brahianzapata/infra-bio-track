terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

locals {
  ecr_subjects = [for r in var.microservice_repos : "repo:${var.github_org}/${r}:ref:refs/heads/main"]
  eks_subject  = "repo:${var.github_org}/infra-bio-track:ref:refs/heads/main"
}

# Role for microservice repos → ECR push
resource "aws_iam_role" "github_ecr" {
  name = "${var.cluster_name}-github-ecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.ecr_subjects }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_ecr_push" {
  role = aws_iam_role.github_ecr.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:DescribeRepositories",
        ]
        Resource = "arn:aws:ecr:*:${var.aws_account_id}:repository/usrv-bio-track-*"
      }
    ]
  })
}

# Role for infra-bio-track → helm upgrade on EKS
resource "aws_iam_role" "github_eks" {
  name = "${var.cluster_name}-github-eks"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.eks_subject
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_eks_access" {
  role = aws_iam_role.github_eks.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "arn:aws:eks:*:${var.aws_account_id}:cluster/${var.cluster_name}"
    }]
  })
}
