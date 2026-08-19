resource "aws_kms_key" "default" {
  region              = var.region
  description         = var.name
  enable_key_rotation = true

  tags = merge(
    local.tags,
    {
      "Name" = var.name
  })
}

resource "aws_kms_alias" "default" {
  region        = var.region
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.default.key_id
}
