output "filesystems" {
  value = length(var.efs_file_systems) > 0 ? {
    for fs_name, fs_config in aws_efs_file_system.default : fs_name => {
      # resource identifiers
      file_system_id  = aws_efs_file_system.default[fs_name].id
      file_system_arn = aws_efs_file_system.default[fs_name].arn

      # DNS name for mounting
      dns_name = aws_efs_file_system.default[fs_name].dns_name

      # mount target IDs for this file system
      mount_target_ids = [
        for mt_key, mt in aws_efs_mount_target.default :
        mt.id if startswith(mt_key, "${fs_name}-")
      ]

      # Configuration
      performance_mode = aws_efs_file_system.default[fs_name].performance_mode
      throughput_mode  = aws_efs_file_system.default[fs_name].throughput_mode
    }
  } : { null = null }
  description = "(Avro Optional) Map of EFS file system connection and resource information"
}

output "access_points" {
  value = length(local.efs_access_points) > 0 ? {
    for ap_key, ap_config in aws_efs_access_point.default : ap_key => {
      access_point_id     = aws_efs_access_point.default[ap_key].id
      access_point_arn    = aws_efs_access_point.default[ap_key].arn
      file_system_id      = aws_efs_access_point.default[ap_key].file_system_id
      file_system_arn     = aws_efs_access_point.default[ap_key].file_system_arn
      root_directory_path = try(aws_efs_access_point.default[ap_key].root_directory[ap_key].path, "/")
      posix_user_gid      = try(aws_efs_access_point.default[ap_key].posix_user[0].gid, null)
      posix_user_uid      = try(aws_efs_access_point.default[ap_key].posix_user[0].uid, null)
    }
  } : { null = null }
}
