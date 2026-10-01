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
  validation {
    condition     = length(var.tenant) <= 6
    error_message = "tenant must be 6 characters or fewer."
  }
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
  validation {
    condition     = contains(["us-east-1", "us-west-1", "us-west-2", "eu-west-2"], var.primary_region)
    error_message = "primary_region must be one of: us-east-1, us-west-1, us-west-2, eu-west-2."
  }
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
  validation {
    condition = alltrue([
      for region in var.workbench_regions : contains(["us-east-1", "us-west-1", "us-west-2", "eu-west-2"], region)
    ])
    error_message = "workbench_regions may only contain a subset of: us-east-1, us-west-1, us-west-2, eu-west-2."
  }
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
  description = "A map of features to enable or disable for the workbench. Each feature can have its own set of variables and configurations. This is used to conditionally create resources based on the features that are enabled. Every top-level feature key is optional, as are the fields within it; anything omitted falls back to the defaults declared below."
  type = object({
    aurora_serverless = optional(object({
      enabled            = optional(bool, true)
      postgresql_version = optional(string, "16.13")
      master_username    = optional(string, "wbadmin")
      clusters = optional(map(map(any)), {
        us-east-1 = {
          cluster-01 = {} # identifier becomes vwb-main-useast1-aurora-cluster-01
        }
        us-west-1 = {
          cluster-01 = {} # identifier becomes vwb-main-uswest1-aurora-cluster-01
        }
        us-west-2 = {
          cluster-01 = {} # identifier becomes vwb-main-uswest2-aurora-cluster-01
        }
        eu-west-2 = {
          cluster-01 = {} # identifier becomes vwb-main-euwest2-aurora-cluster-01
        }
      })
    }), {})
    ecr_endpoints = optional(object({
      enabled          = optional(bool, false)
      excluded_regions = optional(list(string), [])
    }), {})
    s3_endpoints = optional(object({
      enabled          = optional(bool, true)
      excluded_regions = optional(list(string), [])
    }), {})
    omics = optional(object({
      enabled          = optional(bool, true)
      excluded_regions = optional(list(string), [])
    }), {})
    notebook = optional(object({
      enabled          = optional(bool, true)
      excluded_regions = optional(list(string), [])
    }), {})
    efs = optional(object({
      enabled          = optional(bool, false)
      filesystems      = optional(map(any), {})
      excluded_regions = optional(list(string), [])
    }), {})
  })
  default = {}
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
}

# --- tags ---

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
