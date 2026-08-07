# --- kms key for bucket encryption ---

resource "aws_kms_key" "discovery_bucket" {
  description         = local.kms_key_alias
  enable_key_rotation = true

  tags = merge(
    local.tags,
    { "Name" = local.kms_key_alias }
  )
}

resource "aws_kms_alias" "default" {
  name          = "alias/${local.kms_key_alias}"
  target_key_id = aws_kms_key.discovery_bucket.key_id
}
