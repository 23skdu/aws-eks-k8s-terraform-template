##############################################################################
# modules/security/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty with EKS runtime threat detection."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config rules for EKS compliance checks."
  type        = bool
  default     = false
}

variable "config_s3_bucket" {
  description = "S3 bucket for AWS Config delivery channel. Required when enable_aws_config = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
