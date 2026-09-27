##############################################################################
# modules/statebucket/outputs.tf
##############################################################################

output "bucket_id" {
  description = "Name (ID) of the S3 state bucket."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the S3 state bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB state lock table."
  value       = aws_dynamodb_table.state_lock.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB state lock table."
  value       = aws_dynamodb_table.state_lock.arn
}
