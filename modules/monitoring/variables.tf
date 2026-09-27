##############################################################################
# modules/monitoring/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "enable_alerting" {
  description = "Create CloudWatch alarms and SNS topic for EKS alerts."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications. Leave empty to disable."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting the SNS topic."
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage that triggers the high-CPU alarm."
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "cpu_alarm_threshold must be between 1 and 100."
  }
}

variable "memory_alarm_threshold" {
  description = "Memory utilization percentage that triggers the high-memory alarm."
  type        = number
  default     = 80

  validation {
    condition     = var.memory_alarm_threshold > 0 && var.memory_alarm_threshold <= 100
    error_message = "memory_alarm_threshold must be between 1 and 100."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain Container Insights logs."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention period."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
