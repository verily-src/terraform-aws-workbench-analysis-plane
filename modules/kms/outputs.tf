output "kms_key_id" {
  value = aws_kms_key.default.id
}

output "kms_key_arn" {
  value = aws_kms_key.default.arn
}
