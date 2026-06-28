output "ecr_role_arn" { value = aws_iam_role.github_ecr.arn }
output "eks_role_arn" { value = aws_iam_role.github_eks.arn }
