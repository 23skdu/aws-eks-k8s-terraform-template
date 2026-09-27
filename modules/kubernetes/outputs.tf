##############################################################################
# modules/kubernetes/outputs.tf
##############################################################################

output "namespace_names" {
  description = "Names of the created Kubernetes namespaces."
  value       = [for ns in kubernetes_namespace.namespaces : ns.metadata[0].name]
}

output "gp3_storage_class_name" {
  description = "Name of the gp3 StorageClass."
  value       = kubernetes_storage_class.gp3.metadata[0].name
}
