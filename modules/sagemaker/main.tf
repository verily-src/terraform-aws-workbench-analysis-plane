# To specify lifecycle configurations, add a subdirectory under this directory matching the name of
# the configuration with one or both of "on-create.sh" (create script) and "on-start.sh" (startup
# script).  Then add the name of the directory to locals.lifecycle_configuration_names below.  For
# more info on SageMaker Notebook Lifecycle Configurations please see:
#
# https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html
#

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "default" {
  for_each = {
    for index, config in local.lifecycle_configurations :
    config.name => config
  }

  region    = var.region
  name      = "${local.prefix}-lcc-${lower(each.value.name)}"
  on_create = fileexists(each.value.on_create) ? filebase64(each.value.on_create) : null
  on_start  = fileexists(each.value.on_start) ? filebase64(each.value.on_start) : null
  tags      = local.tags
}
