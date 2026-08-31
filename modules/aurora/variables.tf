variable "prefix" {
  description = "A prefix to use for all resources created by this module. This helps ensure that resource names are unique and easily identifiable as belonging to this module."
  type        = string
}

variable "region" {
  description = "The AWS region to create the Aurora cluster in."
  type        = string
  validation {
    condition     = contains(var.workbench_regions, var.region)
    error_message = "Aurora region must be one of the values in workbench_regions."
  }
}

variable "workbench_regions" {
  description = "A list of AWS regions where the Workbench resources will be deployed. This is used to determine which regions to create Aurora clusters in."
  type        = list(string)
}

variable "resource_tags" {
  description = "A map of tags to apply to Aurora clusters created by this module. This can be used to add additional metadata to the clusters for organization, cost tracking, etc. These tags will also be used in the IAM policies for Aurora access to ensure that the permissions only apply to the specific Aurora clusters that are tagged with these tags."
  type        = map(any)
}

variable "postgresql_version" {
  description = "The major version of PostgreSQL to use for the Aurora cluster. Valid values are 16, 15, and 14."
  type        = string
  default     = "16.11"
}

variable "master_username" {
  description = "The master username for the Aurora cluster. This is required if creating a new cluster (i.e. not using an existing cluster). If using an existing cluster, this value will be ignored."
  type        = string
  default     = "wbadmin"
}

variable "aws_managed_password" {
  description = "Whether to use an AWS-managed password for the master user. If true, a random password will be generated and stored in AWS Secrets Manager. If false, you must provide your own password using the master_password variable. This is required if creating a new cluster (i.e. not using an existing cluster). If using an existing cluster, this value will be ignored."
  type        = bool
  default     = true
}

variable "iam_authentication_enabled" {
  description = "Whether to enable IAM database authentication for the cluster. If true, database users can authenticate using AWS IAM credentials. This is required if creating a new cluster (i.e. not using an existing cluster). If using an existing cluster, this value will be ignored."
  type        = bool
  default     = true
}

variable "min_acu" {
  description = "The minimum Aurora Capacity Units (ACUs) for the cluster if using serverless v2. Must be between 0 and 256. If set to 0, the cluster will be provisioned with a fixed instance size rather than serverless v2."
  type        = number
  default     = 0
  validation {
    condition     = var.min_acu >= 0 && var.min_acu <= 255
    error_message = "min_acu must be between 0 and 255."
  }
}

variable "max_acu" {
  description = "The maximum Aurora Capacity Units (ACUs) for the cluster if using serverless v2. Must be between 1 and 256, and must be greater than or equal to min_acu."
  type        = number
  default     = 256
  validation {
    condition     = var.max_acu >= 1 && var.max_acu <= 256
    error_message = "max_acu must be between 1 and 256 and greater than or equal to min_acu."
  }
}

variable "auto_pause_seconds" {
  description = "The number of seconds of inactivity after which the cluster will automatically pause if using serverless v2. Must be between 300 (5 minutes) and 86400 (24 hours). If min_acu is greater than 0, auto-pause is not compatible with the cluster and this value will be ignored."
  type        = number
  default     = 3600
  validation {
    condition     = var.auto_pause_seconds >= 300 && var.auto_pause_seconds <= 86400
    error_message = "auto_pause_seconds must be between 300 (5 minutes) and 86400 (24 hours)"
  }
}

variable "backup_retention_period_days" {
  description = "The number of days to retain backups for. Must be between 1 and 35."
  type        = number
  default     = 10
  validation {
    condition     = var.backup_retention_period_days >= 1 && var.backup_retention_period_days <= 35
    error_message = "backup_retention_period_days must be between 1 and 35."
  }
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled. Must be in the format hh24:mi-hh24:mi and in UTC time. The start time must be between 00:00 and 23:30, and the end time must be between 00:30 and 00:00 (i.e. the window must be at least 30 minutes long)."
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur. Must be in the format ddd:hh24:mi-ddd:hh24:mi, where ddd is a three-letter abbreviation for the day of the week (Mon, Tue, Wed, Thu, Fri, Sat, Sun) and the times are in UTC. The maintenance window must be at least 30 minutes long."
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the cluster. If true, the cluster cannot be deleted unless deletion protection is first disabled. This helps prevent accidental deletion of the cluster."
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "The identifier to use when creating a final snapshot of the cluster before deletion. If null, no final snapshot will be created. If deletion_protection is true, this value will be ignored and no final snapshot will be created since deletion protection prevents deletion of the cluster in the first place."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module. This can be used to add additional metadata to resources for organization, cost tracking, etc."
  type        = map(string)
  default     = {}
}

# --- regional cluster block configuration ---

variable "clusters" {
  type = map(object(
    {
      postgresql_version = optional(string, "16.11")

      # Enable encryption at rest for the cluster
      storage_encrypted = optional(bool, true)

      # Scaling Options for Serverless v2
      min_acu            = optional(number, 0)
      max_acu            = optional(number, 256)
      auto_pause_seconds = optional(number, 3600) # null = no auto-pause, or 300-86400 seconds (5 min - 24 hrs)

      # Backup and Maintenance Options
      backup_retention_period_days = optional(number, 10)
      preferred_backup_window      = optional(string, "03:00-04:00")
      preferred_maintenance_window = optional(string, "sun:04:30-sun:05:30")

      # Deletion Protection - this helps prevent accidental deletion of the cluster by
      # requiring two actions to delete: first disable deletion protection, then delete
      # the cluster.  When disabling deletion protection, a final snapshot can be taken;
      # set final_snapshot_identifier to a non-null string when disabling deletion
      # protection to ensure a final snapshot is taken.
      deletion_protection       = optional(bool, true)
      final_snapshot_identifier = optional(string, null)

      # Point-in-Time Recovery - restore from a backup of another cluster
      # When specified, creates this cluster as a restore from the source cluster.
      # Must provide EITHER restore_to_time OR use_latest_restorable_time (not both).
      restore_to_point_in_time = optional(object({
        source_cluster_identifier  = string
        restore_type               = optional(string, "copy-on-write") # copy-on-write or full-copy
        restore_to_time            = optional(string, null)            # RFC 3339 format, e.g., "2024-01-15T10:30:00Z"
        use_latest_restorable_time = optional(bool, null)              # Set to true to use latest backup, leave null if using restore_to_time
      }), null)

      # Additional tags to add to the cluster
      additional_tags = optional(map(string), {})
    }
  ))
  description = "A map of Aurora cluster identifiers to be used by the landing zone."
  default     = {}
}

# --- network variables ---

variable "vpc_id" {
  description = "The ID of the VPC to create the Aurora cluster in. This is required for creating new clusters. If using an existing cluster, this value will be ignored."
  type        = string
}

variable "vpc_private_subnet_cidrs" {
  description = "A list of CIDR blocks for the private subnets in the VPC."
  type        = list(string)
  default     = []
}
