##############################################################################
# tf/variables.tf
# All input variables for the root module.
##############################################################################

# ── Global ────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy the EKS cluster into."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and prefix for all associated resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, test."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ── KMS ───────────────────────────────────────────────────────────────────────

variable "kms_deletion_window_in_days" {
  description = "Number of days before KMS key deletion (7-30)."
  type        = number
  default     = 7
}

# ── State Bucket ──────────────────────────────────────────────────────────────

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state."
  type        = string
}

variable "state_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "terraform-state-lock"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones to deploy into (minimum 2)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "flow_log_retention_days" {
  description = "Days to retain VPC flow logs."
  type        = number
  default     = 30
}

# ── EKS ───────────────────────────────────────────────────────────────────────

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

variable "endpoint_public_access" {
  description = "Expose the EKS API server endpoint publicly."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS public endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  description = "CIDR for Kubernetes service IPs."
  type        = string
  default     = "172.20.0.0/16"
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types to send to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Days to retain EKS and monitoring logs in CloudWatch."
  type        = number
  default     = 90
}

# ── General Node Group ────────────────────────────────────────────────────────

variable "general_instance_types" {
  description = "EC2 instance types for the general-purpose node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "general_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "general_desired_size" {
  description = "Desired node count for the general node group."
  type        = number
  default     = 2
}

variable "general_min_size" {
  description = "Minimum node count for the general node group."
  type        = number
  default     = 1
}

variable "general_max_size" {
  description = "Maximum node count for the general node group."
  type        = number
  default     = 10
}

variable "general_disk_size_gb" {
  description = "EBS disk size in GB for general nodes."
  type        = number
  default     = 50
}

# ── System Node Group ─────────────────────────────────────────────────────────

variable "system_instance_types" {
  description = "EC2 instance types for the system node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "system_desired_size" {
  description = "Desired node count for the system node group."
  type        = number
  default     = 2
}

variable "system_min_size" {
  description = "Minimum node count for the system node group."
  type        = number
  default     = 1
}

variable "system_max_size" {
  description = "Maximum node count for the system node group."
  type        = number
  default     = 5
}

variable "system_disk_size_gb" {
  description = "EBS disk size in GB for system nodes."
  type        = number
  default     = 50
}

# ── IAM / IRSA ────────────────────────────────────────────────────────────────

variable "enable_alb_controller" {
  description = "Create IRSA role for the AWS Load Balancer Controller."
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Create IRSA role for the Cluster Autoscaler."
  type        = bool
  default     = true
}

# ── Kubernetes ────────────────────────────────────────────────────────────────

variable "namespaces" {
  description = "Kubernetes namespaces to create."
  type        = list(string)
  default     = ["staging", "production"]
}

# ── Monitoring ────────────────────────────────────────────────────────────────

variable "enable_alerting" {
  description = "Create CloudWatch alarms and SNS topic."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email for CloudWatch alarm notifications."
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = "CPU % that triggers the high-CPU alarm."
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory % that triggers the high-memory alarm."
  type        = number
  default     = 80
}

# ── Security ──────────────────────────────────────────────────────────────────

variable "enable_guardduty" {
  description = "Enable GuardDuty with EKS runtime protection."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config EKS compliance rules."
  type        = bool
  default     = false
}

variable "config_s3_bucket" {
  description = "S3 bucket for AWS Config delivery. Required when enable_aws_config = true."
  type        = string
  default     = ""
}
