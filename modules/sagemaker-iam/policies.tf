data "aws_iam_policy_document" "sagemaker_user_sagemaker" {
  statement {
    sid = "TagBased"

    actions = [
      "sagemaker:CreatePresignedNotebookInstanceUrl",
      "sagemaker:DescribeNotebookInstance",
      "sagemaker:DescribeNotebookInstanceLifecycleConfig",
      "sagemaker:ListNotebookInstances",
      "sagemaker:ListTags",
      "sagemaker:StartNotebookInstance",
      "sagemaker:StopNotebookInstance"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "sagemaker:ResourceTag/${var.resource_tags.user_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.user_id}}"]
    }
  }

  # We would like to enable the following actions, but they currently do not support resource-level
  # permissions, thus we would need to allow them for all resources.  This is too permissive if
  # multiple landing zones share an account.  Further, we'd likely want access to code repositories
  # to be limited to a Terra user:
  #
  #   sagemaker:ListCodeRepositories (user scoped)
  #   sagemaker:ListNotebookInstanceLifecycleConfigs (landing-zone scoped)
  #
  # Ref: https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonsagemaker.html
  #
}

data "aws_iam_policy_document" "sagemaker_manager_deny" {
  statement {
    sid    = "DenyUserPrivileges"
    effect = "Deny"
    actions = [
      "sagemaker:CreatePresignedNotebookInstanceUrl",
    ]
    resources = ["*"]
  }
}
