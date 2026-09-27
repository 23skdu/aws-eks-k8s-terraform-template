##############################################################################
# modules/iam/outputs.tf
##############################################################################

output "cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane."
  value       = aws_iam_role.cluster.arn
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by the EKS managed node groups."
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "Name of the IAM role used by the EKS managed node groups."
  value       = aws_iam_role.node_group.name
}
