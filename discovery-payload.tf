locals {
  # --- payloads ---

  workbench_global_values = {
    allowed_bucket_object_role_principal_arns = [local.execution_role_arn_pattern]
    allowed_bucket_object_role_unique_ids = [
      local.workbench_user_unique_id,
      local.workspace_manager_unique_id,
      local.omics_user_delegate_unique_id
    ]
    app_instance_profile_name = {
      string = local.app_instance_profile_name
    }
    kms_key_alias = local.kms_key_alias
    metadata = {
      account_id        = local.account_id
      environment_alias = var.environment
      major_version     = local.major_version
      organization_id   = "not-used" # this field is deprecated and will be removed in future versions, as it is redundant with account_id
      region            = var.primary_region
      tags              = local.tags
      tenant_alias      = var.tenant
    }
    eventbridge_bus_arn_omics = local.omics_eventbridge_bus_arn
    policy_arn_omics_boundary = local.omics_execution_permission_boundary_policy_arn
    queue_url_omics           = local.omics_sqs_queue_url
    role_arn_app_instance = {
      string = local.app_instance_role_arn
    }
    role_arn_axon_server             = local.axon_server_role_arn
    role_arn_external_access         = local.external_access_role_arn
    role_arn_omics_bus_invoker       = local.omics_events_bus_invoke_role_arn
    role_arn_omics_user_delegate     = local.omics_user_delegate_role_arn
    role_arn_terra_notebook          = local.notebook_role_arn
    role_arn_terra_user              = local.workbench_user_role_arn
    role_arn_workflow_manager        = local.workflow_manager_role_arn
    role_arn_terra_workspace_manager = local.workspace_manager_role_arn
  }

  # regional output values - dynamically built per region
  workbench_regional_values = {
    for region in var.workbench_regions : region => {
      # vpc and subnet information
      app_framework_private_subnet_id = {
        string = module.vpc[region].private_subnet_id
      }
      app_framework_private_subnet_ext_id = {
        string = module.vpc[region].private_subnet_id_ext
      }
      app_framework_private_subnets_by_az = {
        map = module.vpc[region].private_subnets_by_az
      }
      app_framework_vpc_id = {
        string = module.vpc[region].vpc_id
      }
      # core resources
      bucket_arn  = module.workbench_bucket[region].bucket_arn
      bucket_id   = module.workbench_bucket[region].bucket_id
      kms_key_arn = module.kms[region].kms_key_arn
      kms_key_id  = module.kms[region].kms_key_id

      # metadata object
      metadata = {
        tenant_alias      = var.tenant
        organization_id   = "not-used" # this field is deprecated and will be removed in future versions, as it is redundant with account_id
        environment_alias = var.environment
        account_id        = local.account_id
        region            = region
        major_version     = local.major_version
        tags              = local.tags
      }

      notebook_lifecycle_configuration_arns  = module.sagemaker[region].notebook_lifecycle_configuration_arns
      notebook_lifecycle_configuration_names = module.sagemaker[region].notebook_lifecycle_configuration_names

      aurora_clusters = contains(local.aurora_regions, region) ? {
        map = module.aurora_cluster[region].clusters
        } : {
        "null" = null
      }
      efs_file_systems = contains(local.efs_regions, region) ? {
        map = module.efs[region].filesystems
        } : {
        "null" = null
      }
      efs_access_points = contains(local.efs_regions, region) ? {
        map = module.efs[region].access_points
        } : {
        "null" = null
      }
    }
  }

  # --- build the s3 object content ---

  workbench_global_payload = {
    for field in local.workbench_global_schema.fields :
    field.name => local.workbench_global_values[field.name]
  }

  workbench_regional_payload = {
    for region in var.workbench_regions : region => {
      for field in local.workbench_regional_schema.fields :
      field.name => local.workbench_regional_values[region][field.name]
    }
  }
}

# --- record the output in s3 ---

resource "aws_s3_object" "environment" {
  key    = format("%s/environment/%s", local.major_version, local.object_key)
  bucket = module.discovery_bucket.discovery_bucket_versioning_id

  content = jsonencode({
    "schema"  = base64encode(jsonencode(local.workbench_global_schema))
    "payload" = base64encode(jsonencode(local.workbench_global_payload))
  })
  tags = local.tags
}

resource "aws_s3_object" "landingzone" {
  for_each = local.workbench_regional_payload
  key      = format("%s/landingzones/%s/%s", local.major_version, each.key, local.object_key)
  bucket   = module.discovery_bucket.discovery_bucket_versioning_id

  content = jsonencode({
    "schema"  = base64encode(jsonencode(local.workbench_regional_schema))
    "payload" = base64encode(jsonencode(local.workbench_regional_payload[each.key]))
  })
  tags = local.tags
}
