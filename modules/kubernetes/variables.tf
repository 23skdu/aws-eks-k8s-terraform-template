##############################################################################
# modules/kubernetes/variables.tf
##############################################################################

variable "namespaces" {
  description = "List of Kubernetes namespaces to create."
  type        = list(string)
  default     = ["staging", "production"]
}

variable "environment" {
  description = "Deployment environment label (dev, staging, prod)."
  type        = string
}
