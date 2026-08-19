# --- app instance role assume policy ---

data "aws_iam_policy_document" "assume_app_instance" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

# --- cloudwatch logs policy for app instance ---

data "aws_iam_policy_document" "logs_app_instance" {
  statement {
    sid       = "${var.sid_prefix}AllowCreateLogGroups"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "${var.sid_prefix}AllowWriteAppInstanceLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/ec2/app-instance/*:*"]
  }
}

# --- ssm policy for app instance ---

data "aws_iam_policy_document" "ssm_user" {
  statement {
    # Limits ability to start SSM Session to this user's instances via
    # Principal "User ID" Tag.
    sid       = "${var.sid_prefix}AllowStartSSMSessionInstance"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/${var.resource_tags.user_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.user_id}}"]
    }
  }

  statement {
    # Limits session types that can be started with SSM.  Document
    # AWS-StartInteractiveCommand is required for non-interactive testing.
    sid     = "${var.sid_prefix}AllowStartSSMSessionDocuments"
    actions = ["ssm:StartSession"]
    resources = [
      "arn:aws:ssm:*:*:document/AWS-StartInteractiveCommand",
      "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
    ]
  }

  statement {
    # Only allows aws:userid ("role/session_id" for assumed role) who started
    # a session to terminate it.
    #
    # Ref: https://aws.amazon.com/blogs/mt/how-to-grant-least-privilege-access-to-third-parties-on-your-private-ec2-instances-with-aws-systems-manager/
    #
    sid       = "${var.sid_prefix}AllowTerminateSSMSession"
    actions   = ["ssm:TerminateSession"]
    resources = ["arn:aws:ssm:*:*:session/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/aws:ssmmessages:session-id"
      values   = ["$${aws:userid}"]
    }
  }
}
