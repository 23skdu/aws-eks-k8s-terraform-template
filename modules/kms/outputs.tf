##############################################################################
# modules/kms/outputs.tf
##############################################################################

output "key_arn" {
  description = "ARN of the KMS key."
  value       = aws_kms_key.eks.arn
}

output "key_id" {
  description = "ID of the KMS key."
  value       = aws_kms_key.eks.key_id
}

output "alias_arn" {
  description = "ARN of the KMS key alias."
  value       = aws_kms_alias.eks.arn
}
