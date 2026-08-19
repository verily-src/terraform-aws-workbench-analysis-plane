
# security group for efs mount targets (shared across all file systems)
resource "aws_security_group" "efs" {
  region = var.region
  name   = "${local.prefix}-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow NFS traffic from App Framework private subnets"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-sg" })
}

# efs file system
resource "aws_efs_file_system" "default" {
  for_each         = var.efs_file_systems
  region           = var.region
  encrypted        = true
  kms_key_id       = var.kms_key_id
  performance_mode = each.value.performance_mode
  throughput_mode  = each.value.throughput_mode

  lifecycle_policy {
    transition_to_ia = each.value.transition_to_ia
  }

  tags = merge(
    local.tags,
    each.value.additional_tags,
    {
      "Name" = "${local.prefix}-${each.key}"
    }
  )
}

# efs mount targets - one per availability zone per file system
resource "aws_efs_mount_target" "default" {
  for_each = {
    for mt in local.efs_mount_targets : mt.key => mt
  }
  region          = var.region
  file_system_id  = aws_efs_file_system.default[each.value.fs_name].id
  subnet_id       = each.value.subnet_id
  security_groups = [aws_security_group.efs.id]
}

# efs file system policy - enforce TLS and deny anonymous access
resource "aws_efs_file_system_policy" "default" {
  for_each       = aws_efs_file_system.default
  region         = var.region
  file_system_id = each.value.id
  policy         = data.aws_iam_policy_document.efs_policy[each.key].json
}

# efs access points
resource "aws_efs_access_point" "default" {
  for_each       = local.efs_access_points
  region         = var.region
  file_system_id = aws_efs_file_system.default[each.value.fs_name].id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_uid   = creation_info.value.owner_uid
          owner_gid   = creation_info.value.owner_gid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.prefix}-ap-${each.value.ap_name}"
    }
  )
}
