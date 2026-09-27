##############################################################################
# modules/irsa/outputs.tf
##############################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC identity provider (without https://)."
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

output "alb_controller_role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller."
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : ""
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role for the Cluster Autoscaler."
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : ""
}

output "ebs_csi_role_arn" {
  description = "ARN of the IRSA role for the EBS CSI driver."
  value       = aws_iam_role.ebs_csi.arn
}
