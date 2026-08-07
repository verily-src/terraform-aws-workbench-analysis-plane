# --- workbench variables ---

variable "semver_version" {
  description = "The semantic version of the workbench. This is used for tagging and naming purposes. It should be in the format of major.minor.patch (e.g. 1.0.0)."
  type        = string
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.semver_version))
    error_message = "semver_version must be in the format of vmajor.minor.patch (e.g. v1.0.0)."
  }
}

variable "deployment_id" {
  description = "The workbench id to use for naming resources. This should be unique across the organization."
  type        = string
  default     = "main"
  validation {
    condition     = length(var.deployment_id) >= 3 && length(var.deployment_id) <= 5
    error_message = "deployment_id must be between 3 and 5 characters."
  }
}

variable "enable_resource_protection" {
  description = "Whether to enable resource protection for buckets e.a. resources"
  type        = bool
  default     = true
}

variable "account_name" {
  description = "The name of the AWS account. This is used for naming resources and for display purposes."
  type        = string
}

variable "tenant" {
  description = "The tenant that this workbench is being deployed for. This is used for tagging and naming purposes."
  type        = string
}

variable "environment" {
  description = "The environment that this workbench is being deployed for. This is used for tagging and naming purposes."
  type        = string
  validation {
    condition     = can(regex("^(dev|test|stage|prod)$", var.environment))
    error_message = "environment must be one of dev, test, stage, or prod."
  }
}

variable "primary_region" {
  description = "The primary AWS region for the workbench. This is used for naming resources and for display purposes. It is also used as the default region for resources that do not have a region specified."
  type        = string
  default     = "us-east-1"
}

variable "workbench_regions" {
  description = "The AWS regions to deploy the workbench resources in."
  type        = list(string)
  default = [
    "us-east-1",
    "us-west-1",
    "us-west-2",
    "eu-west-2",
  ]
}

variable "max_availability_zones" {
  description = "The maximum number of availability zones to use for the workbench resources."
  type        = string
  default     = "max"
  validation {
    condition     = can(regex("^([2-4]|max)$", var.max_availability_zones))
    error_message = "max_availability_zones must be 2, 3, 4, or max."
  }
}

variable "features" {
  description = "A map of features to enable or disable for the workbench. Each feature can have its own set of variables and configurations. This is used to conditionally create resources based on the features that are enabled."
  type        = any
  default     = {}
}

# --- inputs used for regression tests ---
# The variable(s) below are used for test workflows. By default we do not want to
# enable these. They are ONLY enabled in the tests/ terraform configuration.

variable "regression_testing_assume_role_arns" {
  description = "A list of ARNs for additional IAM roles to allow assuming, used for regression testing."
  type        = list(string)
  default     = []
}

# --- gcp service account identifiers ---

variable "gcp_oauth_accounts" {
  type = map(object({
    oauth = object({
      audience = string
      ids = object({
        authnz            = string
        axon_server       = string
        workspace_manager = string
        workflow_manager  = string
      })
    })
  }))
  default = {
    # common devel service accounts
    devel = {
      oauth = {
        audience = "aws_terra_devel"
        ids = {
          workspace_manager = "103839170783841758891"
          workflow_manager  = "116230365760589687692"
          authnz            = "109779806118261264215"
          axon_server       = "115222078872295738259"
        }
      }
    }
    # common dev service accounts
    dev = {
      oauth = {
        audience = "aws_workbench_dev"
        ids = {
          workspace_manager = "114909651314496481017"
          workflow_manager  = "102937181090438264814"
          authnz            = "116303836342211387450"
          axon_server       = "115222078872295738259"
        }
      }
    }
    # common test service accounts
    test = {
      oauth = {
        audience = "aws_workbench_test"
        ids = {
          workspace_manager = "105660334668002635897"
          workflow_manager  = "110770441947027683471"
          authnz            = "109450723473110461688"
          axon_server       = "112598271154440002464"
        }
      }
    }
    # common prod service accounts
    prod = {
      oauth = {
        audience = "aws_workbench_prod"
        ids = {
          workspace_manager = "106070837874473815265"
          workflow_manager  = "113928377999013167748"
          authnz            = "104230373849889301972"
          axon_server       = "103709590145107260341"
        }
      }
    }
  }
}

# --- tags ---

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
