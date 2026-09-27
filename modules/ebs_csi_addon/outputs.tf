##############################################################################
# modules/ebs_csi_addon/outputs.tf
##############################################################################

output "addon_arn" {
  description = "ARN of the aws-ebs-csi-driver add-on."
  value       = aws_eks_addon.ebs_csi_driver.arn
}

output "addon_version" {
  description = "Version of the aws-ebs-csi-driver add-on."
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}
