# tf/ — Root Terraform Configuration

This directory contains the root Terraform configuration that wires together all
child modules to deploy a production-ready EKS cluster on AWS.

## Files

| File | Purpose |
|------|---------|
| [`main.tf`](main.tf) | Provider configuration (`aws`, `kubernetes`, `tls`) and backend block |
| [`modules.tf`](modules.tf) | Calls each child module and passes outputs between them |
| [`variables.tf`](variables.tf) | All input variables with types, defaults, and validation rules |
| [`outputs.tf`](outputs.tf) | All exposed outputs (cluster endpoint, VPC IDs, IAM role ARNs, etc.) |
| [`terraform.tfvars.example`](terraform.tfvars.example) | Copy and populate this file as `terraform.tfvars` |

## Variable Groups

| Group | Key Variables |
|-------|--------------|
| **Global** | `aws_region`, `cluster_name`, `environment`, `tags` |
| **KMS** | `kms_deletion_window_in_days` |
| **State** | `state_bucket_name`, `state_lock_table_name` |
| **Networking** | `vpc_cidr`, `availability_zones`, `public/private_subnet_cidrs` |
| **EKS** | `kubernetes_version`, `endpoint_public_access`, `enabled_cluster_log_types` |
| **General nodes** | `general_instance_types`, `general_capacity_type`, `general_desired/min/max_size` |
| **System nodes** | `system_instance_types`, `system_desired/min/max_size` |
| **IAM / IRSA** | `enable_alb_controller`, `enable_cluster_autoscaler` |
| **Monitoring** | `enable_alerting`, `alert_email`, `cpu/memory_alarm_threshold` |
| **Security** | `enable_guardduty`, `enable_aws_config` |

## Usage

```bash
# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# 2. Bootstrap KMS + state bucket (first time only)
terraform init -backend=false
terraform apply -target=module.kms -target=module.statebucket

# 3. Configure S3 backend in main.tf, then migrate state
terraform init

# 4. Deploy
terraform plan
terraform apply

# 5. Configure kubectl
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

## Module Dependency Graph

```
kms
├── statebucket (depends on kms)
├── networking
├── eks (depends on networking, iam)
│   └── iam (depends on eks OIDC URL — circular via depends_on)
├── kubernetes (depends on eks)
├── monitoring (depends on kms)
└── security
```

> **Note:** The `iam` module requires the EKS OIDC issuer URL (available only
> after the cluster is created). This creates a soft circular dependency that
> Terraform resolves through the explicit `depends_on = [module.eks]` directive
> in `modules.tf`.

## Key Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | API server URL (sensitive) |
| `cluster_oidc_issuer_url` | OIDC issuer for IRSA |
| `oidc_provider_arn` | IRSA OIDC provider ARN |
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs for node groups |
| `configure_kubectl` | Ready-to-run `aws eks update-kubeconfig` command |
| `alb_controller_role_arn` | IRSA ARN for AWS Load Balancer Controller |
| `cluster_autoscaler_role_arn` | IRSA ARN for Cluster Autoscaler |
