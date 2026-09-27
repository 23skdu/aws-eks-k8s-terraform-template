##############################################################################
# modules/monitoring/outputs.tf
##############################################################################

output "sns_topic_arn" {
  description = "ARN of the SNS alerting topic."
  value       = var.enable_alerting ? aws_sns_topic.alerts[0].arn : ""
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.eks.dashboard_name
}

output "container_insights_log_group" {
  description = "Name of the CloudWatch log group for Container Insights."
  value       = aws_cloudwatch_log_group.container_insights.name
}
