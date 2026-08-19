variable "prefix" {
  description = "A prefix to use for all resources created by this module. This helps ensure that resource names are unique and easily identifiable as belonging to this module."
  type        = string
}

variable "region" {
  description = "The AWS region to create the Aurora cluster in."
  type        = string
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

variable "restore_to_point_in_time" {
  description = "An optional configuration block to specify that the cluster should be created as a restore from a backup of another cluster. If specified, must provide either restore_to_time or use_latest_restorable_time (not both). If not specified, the cluster will be created as a new cluster rather than a restore."
  type = object({
    source_cluster_identifiers = map(string)
    restore_type               = optional(string, "copy-on-write") # copy-on-write or full-copy
    restore_to_time            = optional(string, null)            # RFC 3339 format, e.g., "2024-01-15T10:30:00Z"
    use_latest_restorable_time = optional(bool, null)              # Set to true to use latest backup, leave null if using restore_to_time
  })
  default = null
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
