# actuate build
locals {
  account_id = data.aws_caller_identity.current.account_id

  workbench_prefix  = "vwb-${var.deployment_id}"
  workbench_version = var.semver_version
  major_version     = split(".", local.workbench_version)[0]

  # --- workbench sid prefix
  # this is used as a prefix for the sids in the iam policies to ensure they are unique.
  sid_prefix = "Vwb"

  # --- iam denied resources
  # construct the list of denied buckets and resources
  protected_buckets_arns = [
    for bucket in var.protected_buckets :
    "arn:aws:s3:::${bucket}"
  ]
  iam_denied_objects = [
    for bucket in local.protected_buckets_arns : "${bucket}/*" if substr(bucket, -1, 1) != "*"
  ]
  iam_denied_resources = concat(local.iam_denied_objects, local.protected_buckets_arns)

  # --- gcp service account JWT attributes
  gcp_service_accounts = {
    aud = var.gcp_oauth_accounts[var.environment].oauth.audience
    sub = [
      var.gcp_oauth_accounts[var.environment].oauth.ids.workspace_manager,
      var.gcp_oauth_accounts[var.environment].oauth.ids.workflow_manager,
      var.gcp_oauth_accounts[var.environment].oauth.ids.authnz,
      var.gcp_oauth_accounts[var.environment].oauth.ids.axon_server
    ]
  }
}
