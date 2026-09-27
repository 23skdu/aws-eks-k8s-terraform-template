##############################################################################
# modules/kms/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Number of days before the KMS key is deleted after scheduling deletion."
  type        = number
  default     = 7

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
