# --- user actions policy ---

data "aws_iam_policy_document" "aurora_user_actions" {
  statement {
    sid     = "${var.sid_prefix}RDSConnectAsUser"
    effect  = "Allow"
    actions = ["rds-db:connect"]

    # Resource is computed from the passed principal tags:
    # - DatabaseCluster must be set to the ID of the cluster to connect to
    # - DatabaseName must be set to the name of the database to connect to
    # - DatabaseAccess must be set to either "ro" or "rw" depending on
    resources = [
      "arn:aws:rds-db:*:${var.account_id}:dbuser:$${aws:PrincipalTag/${var.principal_tags.database_cluster}}/$${aws:PrincipalTag/${var.principal_tags.database_name}}_$${aws:PrincipalTag/${var.principal_tags.database_access}}"
    ]

    # Enforce that DatabasAccess tag must be either "ro" or "rw"
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.database_access}"
      values   = ["ro", "rw"]
    }

    # Enforce that DatabaseAccess, DatabaseCluster, and DatabaseName principal tags are all set
    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${var.principal_tags.database_access}"
      values   = ["false"]
    }

    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${var.principal_tags.database_cluster}"
      values   = ["false"]
    }

    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${var.principal_tags.database_name}"
      values   = ["false"]
    }
  }
}

# --- workspace manager policies ---

data "aws_iam_policy_document" "aurora_manager_admin" {
  statement {
    sid       = "${var.sid_prefix}RDSConnectAsAdmin"
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:*:${var.account_id}:dbuser:*/${var.aurora_master_username}"]
  }

  statement {
    sid    = "${var.sid_prefix}RDSExecuteSQL"
    effect = "Allow"

    actions = [
      "rds-data:BeginTransaction",
      "rds-data:ExecuteStatement",
      "rds-data:CommitTransaction",
      "rds-data:RollbackTransaction",
    ]
    resources = ["arn:aws:rds:*:${var.account_id}:cluster:*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${var.resource_tags.aurora}"
      values   = ["true"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}RDSDescribeClusters"
    effect = "Allow"

    actions = [
      "rds:DescribeDBClusters",
      "rds:ListTagsForResource",
    ]
    resources = ["arn:aws:rds:*:${var.account_id}:cluster:*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${var.resource_tags.aurora}"
      values   = ["true"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}SecretsManagerGetMasterPassword"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    # Allow access to secrets that are managed by RDS for Aurora clusters
    # The secret ARN pattern for RDS-managed secrets is:
    # arn:aws:secretsmanager:region:account:secret:rds!cluster-{cluster-uuid}-{random}
    resources = ["arn:aws:secretsmanager:*:${var.account_id}:secret:rds!cluster-*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${var.resource_tags.aurora}"
      values   = ["true"]
    }
  }
}
