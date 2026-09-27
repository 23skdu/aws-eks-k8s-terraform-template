##############################################################################
# modules/statebucket/variables.tf
##############################################################################

variable "bucket_name" {
  description = "Globally unique name for the S3 Terraform state bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name (3-63 chars, lowercase, hyphens/dots allowed)."
  }
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  type        = string
  default     = "terraform-state-lock"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting state bucket and lock table."
  type        = string
}

variable "access_log_bucket" {
  description = "S3 bucket name for server access logging. Leave empty to disable."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
