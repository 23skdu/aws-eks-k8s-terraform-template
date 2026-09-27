##############################################################################
# modules/eks/variables.tf
##############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase alphanumeric characters or hyphens."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"

  validation {
    condition     = can(regex("^1\\.[2-9][0-9]$", var.kubernetes_version))
    error_message = "kubernetes_version must be a valid EKS version like '1.31'."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster and node groups."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for EKS high availability."
  }
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS control plane."
  type        = string
}

variable "node_group_role_arn" {
  description = "ARN of the IAM role for EKS node groups."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting EKS secrets and EBS volumes."
  type        = string
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IP addresses."
  type        = string
  default     = "172.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.service_ipv4_cidr))
    error_message = "service_ipv4_cidr must be a valid CIDR block."
  }
}

variable "enabled_cluster_log_types" {
  description = "List of EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Number of days to retain EKS control plane logs in CloudWatch."
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention period."
  }
}

# ── General Node Group ────────────────────────────────────────────────────────

variable "general_instance_types" {
  description = "EC2 instance types for the general-purpose node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "general_capacity_type" {
  description = "Capacity type for general nodes: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.general_capacity_type)
    error_message = "general_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "general_desired_size" {
  description = "Desired number of nodes in the general node group."
  type        = number
  default     = 2
}

variable "general_min_size" {
  description = "Minimum number of nodes in the general node group."
  type        = number
  default     = 1
}

variable "general_max_size" {
  description = "Maximum number of nodes in the general node group."
  type        = number
  default     = 10
}

variable "general_disk_size_gb" {
  description = "EBS disk size in GB for general nodes."
  type        = number
  default     = 50

  validation {
    condition     = var.general_disk_size_gb >= 20
    error_message = "general_disk_size_gb must be at least 20 GB."
  }
}

# ── System Node Group ─────────────────────────────────────────────────────────

variable "system_instance_types" {
  description = "EC2 instance types for the system node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "system_desired_size" {
  description = "Desired number of nodes in the system node group."
  type        = number
  default     = 2
}

variable "system_min_size" {
  description = "Minimum number of nodes in the system node group."
  type        = number
  default     = 1
}

variable "system_max_size" {
  description = "Maximum number of nodes in the system node group."
  type        = number
  default     = 5
}

variable "system_disk_size_gb" {
  description = "EBS disk size in GB for system nodes."
  type        = number
  default     = 50

  validation {
    condition     = var.system_disk_size_gb >= 20
    error_message = "system_disk_size_gb must be at least 20 GB."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
