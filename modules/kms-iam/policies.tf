# --- kms user policy ---

data "aws_iam_policy_document" "kms_user" {
  statement {
    sid = "${var.sid_prefix}UserKms"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]

    # KMS keys are a regional resource and created in the Landing Zone, and their ARN includes an
    # AWS-generated UUID.  Thus their ARN cannot be infered at Environment creation time, so we
    # cannot apply the policy to the LZ's KMS key(s) based on resource alone.
    resources = ["arn:aws:kms:*:${var.account_id}:key/*"]

    # Instead we use the resource alias that we expect the LZ to create for the KMS key to limit
    # access to the LZ-specific KMS key via this condition.
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ResourceAliases"
      values   = ["alias/${var.kms_key_alias}"]
    }

    # These two condidtions make sure that the LZ's S3 Bucket is the source of the request.condition {
    # See, https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-encryption-context
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${var.bucket_name_prefix}*"]
    }
  }
}

# --- workspace manager kms policy ---

data "aws_iam_policy_document" "kms_manager" {
  statement {
    sid = "${var.sid_prefix}WorkspaceManagerKms"

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]

    # KMS keys are a regional resource and created in the Landing Zone, and their ARN includes an
    # AWS-generated UUID.  Thus their ARN cannot be infered at Environment creation time, so we
    # cannot apply the policy to the LZ's KMS key(s) based on resource alone.
    resources = ["arn:aws:kms:*:*:key/*"]

    # Instead we use the resource alias that we expect the LZ to create for the KMS key to limit
    # access to the LZ-specific KMS key via this condition.
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ResourceAliases"
      values   = ["alias/${var.kms_key_alias}"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${var.account_id}:role/${var.workspace_manager_role_name}",
      ]
    }
  }
}

# --- kms ec2 grant policy ---

# In order to start a stopped EC2 instance, a user must be able to perform action kms:CreateGrant
# to grant the EC2 service the ability to use the KMS key for disk volume decryption while
# launching the instance.
data "aws_iam_policy_document" "kms_user_ec2_instance_create_grant" {
  statement {
    sid     = "UserEc2Instance"
    actions = ["kms:CreateGrant"]

    # KMS keys are a regional resource and created in the Landing Zone, and their ARN includes an
    # AWS-generated UUID.  Thus their ARN cannot be infered at Environment creation time, so we
    # cannot apply the policy to the LZ's KMS key(s) based on resource alone.
    resources = ["arn:aws:kms:*:*:key/*"]

    # Instead we use the resource alias that we expect the LZ to create for the KMS key to limit
    # access to the LZ-specific KMS key via this condition.
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ResourceAliases"
      values   = ["alias/${var.kms_key_alias}"]
    }

    # The intent of this condition is to ensure that the user can only grant access to the EC2
    # service.  Since the only EC2 actions that the user is allowed to perform are those that
    # start an EC2 instance that the user owns, this effectively limits the user to creating
    # grants for these instances.
    #
    # Ref: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["ec2.*.amazonaws.com"]
    }
  }
}
