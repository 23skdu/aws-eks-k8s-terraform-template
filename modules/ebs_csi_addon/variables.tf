##############################################################################
# modules/ebs_csi_addon/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster to install the add-on on."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase alphanumeric characters or hyphens."
  }
}

variable "ebs_csi_role_arn" {
  description = "ARN of the IRSA role for the EBS CSI driver add-on."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/", var.ebs_csi_role_arn))
    error_message = "ebs_csi_role_arn must be a valid IAM role ARN."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
