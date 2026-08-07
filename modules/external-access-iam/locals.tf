locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-external-access")

  # --- external access iam role name
  external_access_role_name = local.prefix

  # common ECR actions for different permission levels
  ecr_read_actions = [
    "ecr:BatchGetImage",
    "ecr:DescribeImages",
    "ecr:DescribeRepositories",
    "ecr:GetDownloadUrlForLayer",
    "ecr:ListImages",
  ]

  ecr_write_actions = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:BatchDeleteImage",
    "ecr:CompleteLayerUpload",
    "ecr:InitiateLayerUpload",
    "ecr:PutImage",
    "ecr:UploadLayerPart",
  ]

  # common conditions that are reused across statements
  common_account_condition = {
    test     = "StringLike"
    variable = "aws:ResourceAccount"
    values   = ["$${aws:PrincipalTag/${var.principal_tags.external_repository_account}}"]
  }

  common_region_condition = {
    test     = "StringLike"
    variable = "aws:RequestedRegion"
    values   = ["$${aws:PrincipalTag/${var.principal_tags.external_repository_region}}"]
  }

  tags = merge(
    var.tags,
    {}
  )
}
