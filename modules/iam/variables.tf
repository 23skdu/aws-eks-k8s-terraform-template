##############################################################################
# modules/iam/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase alphanumeric characters or hyphens."
  }
}

variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL of the EKS cluster (used to create the OIDC provider for IRSA)."
  type        = string
}

variable "enable_alb_controller" {
  description = "Create IRSA role and policy for the AWS Load Balancer Controller."
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Create IRSA role and policy for the Cluster Autoscaler."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
