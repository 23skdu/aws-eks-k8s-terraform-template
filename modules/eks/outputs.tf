##############################################################################
# modules/eks/outputs.tf
##############################################################################

output "cluster_id" {
  description = "ID of the EKS cluster."
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS Kubernetes API server."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster."
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  description = "ID of the security group attached to the EKS cluster control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "ID of the security group attached to the EKS worker nodes."
  value       = aws_security_group.nodes.id
}

output "general_node_group_arn" {
  description = "ARN of the general-purpose managed node group."
  value       = aws_eks_node_group.general.arn
}

output "system_node_group_arn" {
  description = "ARN of the system managed node group."
  value       = aws_eks_node_group.system.arn
}
