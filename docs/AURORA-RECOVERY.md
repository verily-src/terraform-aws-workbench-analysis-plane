# Aurora PostgreSQL Disaster Recovery Playbook

## Metadata

### Playbook Description

How to perform disaster recovery operations for Aurora PostgreSQL clusters and databases in Verily Workbench AWS environments. This playbook covers the full cluster recovery scenario.

## Overview

This playbook provides procedures for recovering Aurora PostgreSQL clusters used by Workbench Workspace Manager.

### When to Use This Playbook

- **Full Cluster Restore**: Use when an entire Aurora cluster is corrupted, deleted, or needs to be rolled back to a previous state due to:

  - Cluster-level corruption or failure
  - Accidental cluster deletion
  - Disaster recovery testing

### Aurora Backup System

Aurora provides several backup and recovery mechanisms:

- **Automated Snapshots**: Daily automated cluster snapshots with configurable retention (currently 10 days per Terraform configuration)
- **Point-in-Time Recovery (PITR)**: Allows recovery to any specific second within the backup retention period (10 days)
- **Manual Snapshots**: On-demand cluster snapshots that persist until explicitly deleted
- **Backup Window**: Currently configured as 03:00-04:00 UTC per Terraform

**PITR Restore Types**:

Aurora supports two restore types for point-in-time recovery:

1. **`copy-on-write`** (Fast, efficient):

  - ✅ Shares storage with source cluster initially (minimal storage cost)
  - ✅ Faster restore time
  - ❌ **CRITICAL**: Can ONLY restore to latest restorable time (cannot specify timestamp)
  - ❌ Cannot use with `restore_to_time` parameter
  - **Use when**: You want the most recent data and don't need a specific timestamp

2. **`full-copy`** (Flexible, independent):

  - ✅ Can restore to any specific timestamp within retention window
  - ✅ Independent storage (safe for testing)
  - ✅ Works with `restore_to_time` parameter
  - ❌ Uses more storage initially (full data copy)
  - ❌ Slightly slower restore time
  - **Use when**: You need to restore to a specific point in time (typical DR scenario)

**⚠️ AWS API Constraint**: You cannot specify `restore_to_time` when using `restore_type: "copy-on-write"`. This will result in the error: `InvalidParameterCombination: You cannot specify RestoreToTime when RestoreType is copy-on-write.`

For detailed information, see the [AWS Aurora Backup Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html).

## Procedure 1: Full Aurora Cluster Restore

**Use when**: Entire cluster is corrupted, deleted, or needs rollback to previous state.

**Impact**: All databases on the cluster will be restored to the specified point in time.

**Duration**: 2-4 hours (30-60 min cluster creation + validation + cutover)

### Prerequisites

- Access to WSM PostgreSQL database
- Recovery point timestamp identified within PITR window (check with: `aws rds describe-db-clusters`)

### Steps

#### 1\. Assess Impact and Notify Stakeholders

**Fence the old cluster** to prevent new database allocations within this cluster.

Locate the Analysis Plane Terraform and update the `locals.tf`:

- **Example Path**: `.../analysis-plane/main/locals.tf`

- set the additional tag "WorkbenchFenced = true"

- set deletion_protection = false

```hcl
features = {
  aurora_serverless = {
    enabled            = true
    postgresql_version = "16.11"

    clusters = {
      us-east-1 = {
        cluster-01 = { # identifier becomes vwb-main-useast1-aurora-cluster-01
          # restore step 1 - prepare for restore
          deletion_protection = false
          additional_tags = {
            WorkbenchFenced = true
          }
        }
      }
      us-west-2 = {
        cluster-01 = {}
      }
    }
  }
}
```

**Create PR** and apply the Terraform

**Query affected workspaces**

First, identify a known database resource on this cluster and its workspace to determine the org/pod UUIDs. Database resources are scoped by the tuple (org_id, pod_id, region, cluster_identifier), so you need these UUIDs to query all impacted databases:

```sql
-- Get org_id and pod_id UUIDs from known workspace with database on this cluster
SELECT workspace_id, display_name, org_id, pod_id
FROM workspace
WHERE workspace_id = '<known-workspace-uuid>';
-- Returns UUIDs needed for subsequent queries

-- List all affected workspaces and owners using those UUIDs
SELECT
  w.workspace_id,
  w.display_name AS workspace_name,
  w.created_by_email AS workspace_owner,
  r.name AS database_name
FROM resource r
INNER JOIN workspace w ON r.workspace_id = w.workspace_id
WHERE r.exact_resource_type = 'CONTROLLED_AWS_AURORA_DATABASE'
  AND r.stewardship_type = 'CONTROLLED'
  AND r.region = '<region>'
  AND (r.attributes->>'clusterIdentifier') = '<cluster-short-name>'
  AND w.org_id = '<org-uuid>'
  AND w.pod_id = '<pod-uuid>'
ORDER BY w.created_date DESC;
```

**Notify workspace owners** of planned maintenance window.

#### 2\. Create Restored Cluster via Terraform

**⚠️ IMPORTANT**:

1. Make sure to set the full cluster identifier as the `source_cluster_identifier`

  - Example: `source_cluster_identifier = "vwb-main-useast1-aurora-cluster-01"`

2. Choose to set `restore_to_time` or `use_latest_restorable_time`, but not both

3. After the restore procedure is completed, DO NOT delete the `restore_to_point_in_time block`. This will cause AWS to create a new cluster.

**In the same `locals.tf` file:

- add the `restore_to_point_in_time` block
- make sure to set the full cluster identifier as the `source_cluster_identifier`.
- remove or comment out `deletion_protection`

```hcl
features = {
  aurora_serverless = {
    enabled            = true
    postgresql_version = "16.11"

    clusters = {
      us-east-1 = {
        cluster-01 = { # becomes vwb-main-useast1-aurora-cluster-01
          # restore step 1 - prepare for restore
          deletion_protection = false
          additional_tags = {
            WorkbenchFenced = true
          }
        }
        # restore step 2 - trigger restore
        cluster-02 = {
          restore_to_point_in_time = {
            # must use full cluster identifier (ie. vwb-main-useast1-aurora-cluster-01)
            source_cluster_identifier = "vwb-main-useast1-aurora-cluster-01"
            restore_type              = "full-copy"
            restore_to_time           = "2026-08-20T19:00:00Z"

            # if you want the latest snapshot to be restored, set this value to true and comment out the restore_to_time variable.
            use_latest_restorable_time = false
          }
          # Fence the new cluster
          additional_tags = {
            WorkbenchFenced = true
          }
        }
      }
      us-west-2 = {
        cluster-01 = {}
      }
    }
  }
}
```

**Apply Terraform**. Wait 30-60 minutes for cluster creation.

**⚠️ IMPORTANT**:

- After Terraform apply succeeds, **wait at least 15 minutes** for WSM discovery caches to refresh with the new cluster ID and fencing tag.

#### 3\. Update WSM Database to Point to New Cluster

At this point the Workspace Manager needs to be configured to point to the new cluster.

- This step is typically handled by the Verily Workbench Team

- The new cluster identifier and endpoints will be available in the Terraform output

**Preview the change**:

```sql
SELECT
  w.workspace_id,
  w.display_name,
  r.name AS database_name,
  r.attributes->>'clusterIdentifier' AS current_cluster
FROM resource r
INNER JOIN workspace w ON r.workspace_id = w.workspace_id
WHERE r.exact_resource_type = 'CONTROLLED_AWS_AURORA_DATABASE'
  AND r.region = '<region>'
  AND (r.attributes->>'clusterIdentifier') = '<old-cluster-short-name>'
  AND w.org_id = '<org-uuid>'
  AND w.pod_id = '<pod-uuid>';
```

**Execute cutover**:

```sql
UPDATE resource r
SET attributes = jsonb_set(r.attributes, '{clusterIdentifier}', '"<new-cluster-short-name>"'::jsonb)
FROM workspace w
WHERE r.workspace_id = w.workspace_id
  AND r.exact_resource_type = 'CONTROLLED_AWS_AURORA_DATABASE'
  AND r.region = '<region>'
  AND (r.attributes->>'clusterIdentifier') = '<old-cluster-short-name>'
  AND w.org_id = '<org-uuid>'
  AND w.pod_id = '<pod-uuid>';
```

**Verify**:

```sql
-- Confirm all databases now point to new cluster
SELECT COUNT(*) FROM resource r
INNER JOIN workspace w ON r.workspace_id = w.workspace_id
WHERE r.exact_resource_type = 'CONTROLLED_AWS_AURORA_DATABASE'
  AND r.region = '<region>'
  AND (r.attributes->>'clusterIdentifier') = '<new-cluster-short-name>'
  AND w.org_id = '<org-uuid>'
  AND w.pod_id = '<pod-uuid>';

-- Confirm old cluster has zero databases
SELECT COUNT(*) FROM resource r
INNER JOIN workspace w ON r.workspace_id = w.workspace_id
WHERE r.exact_resource_type = 'CONTROLLED_AWS_AURORA_DATABASE'
  AND r.region = '<region>'
  AND (r.attributes->>'clusterIdentifier') = '<old-cluster-short-name>'
  AND w.org_id = '<org-uuid>'
  AND w.pod_id = '<pod-uuid>';
-- Should return 0
```

#### 4\. Test Database Access from Workspace

- This step is typically handled by the Verily Workbench Team

From a Cloud App in a workspace with an impacted database, attempt to connect to the database and confirm data is restored:

```bash
# From within the Cloud App (e.g., JupyterLab, RStudio)
wb resource resolve --name=<database-name> --workspace=<workspace-name>
# Use returned connection string to connect and verify data
```

Alternatively, coordinate with workspace owners to verify connectivity and data integrity from their applications.

#### 5\. Unfence New Cluster and Delete the Old Cluster

**⚠️ IMPORTANT**:

1. You should remove the `restore_to_point_in_time` block. The module uses a lifecycle statement to ignore changes to this block, preventing re-creation of the cluster when removing this block. This ensures AWS applies the correct settings for `database_insights_mode` and `enable_http_endpoint` in the final Terraform cycle.

2. Remove `additional_tags` block to unfence the new cluster:

```hcl
features = {
  aurora_serverless = {
    enabled            = true
    postgresql_version = "16.11"

    clusters = {
      us-east-1 = {
        cluster-02 = {}
      }
      us-west-2 = {
        cluster-01 = {}
      }
    }
  }
}
```

1. Apply Terraform
