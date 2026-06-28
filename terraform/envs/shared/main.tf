terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

provider "aws" { region = var.region }

data "aws_caller_identity" "current" {}

# GitHub OIDC provider — account-level singleton; created once here for all envs
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

module "ecr" {
  source = "../../modules/ecr"
}

module "iam_github_prod" {
  source            = "../../modules/iam-github"
  cluster_name      = "bio-track-prod"
  aws_account_id    = data.aws_caller_identity.current.account_id
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
}

module "iam_github_staging" {
  source            = "../../modules/iam-github"
  cluster_name      = "bio-track-staging"
  aws_account_id    = data.aws_caller_identity.current.account_id
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
}

output "ecr_urls"             { value = module.ecr.repository_urls }
output "prod_ecr_role_arn"    { value = module.iam_github_prod.ecr_role_arn }
output "prod_eks_role_arn"    { value = module.iam_github_prod.eks_role_arn }
output "staging_ecr_role_arn" { value = module.iam_github_staging.ecr_role_arn }
output "staging_eks_role_arn" { value = module.iam_github_staging.eks_role_arn }
