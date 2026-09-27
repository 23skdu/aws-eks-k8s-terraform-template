##############################################################################
# tf/modules.tf
# Wires all child modules together.
##############################################################################

# ── KMS ───────────────────────────────────────────────────────────────────────

module "kms" {
  source = "../modules/kms"

  cluster_name            = var.cluster_name
  deletion_window_in_days = var.kms_deletion_window_in_days
  tags                    = local.common_tags
}

# ── State Bucket ──────────────────────────────────────────────────────────────

module "statebucket" {
  source = "../modules/statebucket"

  bucket_name     = var.state_bucket_name
  lock_table_name = var.state_lock_table_name
  kms_key_arn     = module.kms.key_arn
  tags            = local.common_tags
}

# ── Networking ────────────────────────────────────────────────────────────────

module "networking" {
  source = "../modules/networking"

  cluster_name            = var.cluster_name
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  flow_log_retention_days = var.flow_log_retention_days
  tags                    = local.common_tags
}

# ── EKS Cluster ───────────────────────────────────────────────────────────────

module "eks" {
  source = "../modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  cluster_role_arn    = module.iam.cluster_role_arn
  node_group_role_arn = module.iam.node_group_role_arn
  ebs_csi_role_arn    = module.iam.ebs_csi_role_arn
  kms_key_arn         = module.kms.key_arn

  endpoint_public_access    = var.endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  service_ipv4_cidr         = var.service_ipv4_cidr
  enabled_cluster_log_types = var.enabled_cluster_log_types
  log_retention_days        = var.log_retention_days

  general_instance_types = var.general_instance_types
  general_capacity_type  = var.general_capacity_type
  general_desired_size   = var.general_desired_size
  general_min_size       = var.general_min_size
  general_max_size       = var.general_max_size
  general_disk_size_gb   = var.general_disk_size_gb

  system_instance_types = var.system_instance_types
  system_desired_size   = var.system_desired_size
  system_min_size       = var.system_min_size
  system_max_size       = var.system_max_size
  system_disk_size_gb   = var.system_disk_size_gb

  tags = local.common_tags
}

# ── IAM (IRSA requires OIDC URL from the cluster) ────────────────────────────

module "iam" {
  source = "../modules/iam"

  cluster_name              = var.cluster_name
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  enable_alb_controller     = var.enable_alb_controller
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  tags                      = local.common_tags

  depends_on = [module.eks]
}

# ── Kubernetes Resources ──────────────────────────────────────────────────────

module "kubernetes" {
  source = "../modules/kubernetes"

  namespaces  = var.namespaces
  environment = var.environment

  depends_on = [module.eks]
}

# ── Monitoring ────────────────────────────────────────────────────────────────

module "monitoring" {
  source = "../modules/monitoring"

  cluster_name           = var.cluster_name
  enable_alerting        = var.enable_alerting
  alert_email            = var.alert_email
  kms_key_arn            = module.kms.key_arn
  cpu_alarm_threshold    = var.cpu_alarm_threshold
  memory_alarm_threshold = var.memory_alarm_threshold
  log_retention_days     = var.log_retention_days
  tags                   = local.common_tags
}

# ── Security ──────────────────────────────────────────────────────────────────

module "security" {
  source = "../modules/security"

  cluster_name      = var.cluster_name
  enable_guardduty  = var.enable_guardduty
  enable_aws_config = var.enable_aws_config
  config_s3_bucket  = var.config_s3_bucket
  tags              = local.common_tags
}
