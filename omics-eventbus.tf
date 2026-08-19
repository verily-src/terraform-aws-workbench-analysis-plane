locals {
  # --- omics features
  # this extracts the omics feature configuration from the features variable.
  omics = try(var.features.omics, {
    enabled          = false
    excluded_regions = []
  })

  # --- omics regions
  # if the omics feature is not enabled, set omics_regions to an empty list, otherwise
  # it will adopt the global workbench regions.
  # if there are excluded regions specified, they will be removed from the final list of regions where 
  # omics resources are created. 
  omics_base    = local.omics.enabled ? var.workbench_regions : []
  omics_regions = setsubtract(local.omics_base, local.omics.excluded_regions)

  # --- omics log group and execution role arn pattern
  omics_log_group            = "arn:aws:logs:*:${local.account_id}:log-group:/aws/omics/WorkflowLog:*"
  execution_role_arn_pattern = "arn:aws:iam::${local.account_id}:role/vwbOmicsServiceRoles/*"

  # --- omics user delegate role name
  # gather the omics user delegate role name from the omics_eventbus_iam module
  # note that this is an output value from the module!
  omics_user_delegate_role_name = local.omics.enabled ? module.omics_eventbus_iam["this"].user_delegate_role_name : ""
  omics_user_delegate_unique_id = local.omics.enabled ? module.omics_eventbus_iam["this"].user_delegate_role_unique_id : ""

  # --- omics event bus arn
  # gather the omics event bus arn from the omics_eventbus_iam module
  # note that this is an output value from the module!
  omics_events_bus_invoke_role_arn               = local.omics.enabled ? module.omics_eventbus_iam["this"].event_bus_invoke_role_arn : ""
  omics_eventbridge_bus_arn                      = local.omics.enabled ? module.omics_eventbus_iam["this"].event_bus_arn : ""
  omics_sqs_queue_url                            = local.omics.enabled ? module.omics_eventbus_iam["this"].sqs_events_queue_url : ""
  omics_execution_permission_boundary_policy_arn = local.omics.enabled ? module.omics_eventbus_iam["this"].execution_permission_boundary_policy_arn : ""
  omics_user_delegate_role_arn                   = local.omics.enabled ? module.omics_eventbus_iam["this"].user_delegate_role_arn : ""
}

# --- modules ---

module "omics_eventbus_iam" {
  source = "./modules/omics-eventbus-iam"

  for_each       = local.omics.enabled ? toset(["this"]) : toset([])
  account_id     = local.account_id
  prefix         = local.workbench_prefix
  sid_prefix     = local.sid_prefix
  principal_tags = local.principal_tags
  resource_tags  = local.resource_tags
  tags           = local.workflow_tags

  bucket_name_prefix         = local.bucket_name_prefix
  iam_denied_resources       = local.iam_denied_resources
  workflow_manager_role_name = local.workflow_manager_role_name
  workflow_manager_role_arn  = local.workflow_manager_role_arn
  execution_role_arn_pattern = local.execution_role_arn_pattern
  omics_log_group            = local.omics_log_group

  permission_boundary_policy_documents = [
    module.kms_iam.kms_user_policy_doc
  ]
}

module "omics_eventbus_rule" {
  source = "./modules/omics-eventbus-rule"

  for_each   = toset(local.omics_regions)
  region     = each.value
  account_id = local.account_id
  prefix     = local.workbench_prefix
  tags       = local.workflow_tags

  bus_invoke_role_arn = local.omics_events_bus_invoke_role_arn
  events_bus_arn      = local.omics_eventbridge_bus_arn
}
