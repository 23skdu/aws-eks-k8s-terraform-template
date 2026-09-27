# AWS EKS Kubernetes Terraform Template

Production-ready EKS cluster on AWS with modular architecture, multi-environment support, KMS encryption, and comprehensive Terratest coverage following the golden-file methodology.

## Features

- **7 reusable modules**: `networking`, `iam`, `eks`, `kms`, `monitoring`, `security`, `statebucket`, `kubernetes`
- **Multi-environment** with per-environment `terraform.tfvars` (`dev`, `staging`, `prod`)
- **EKS cluster** with two managed node groups: general-purpose and system (tainted)
- **Private cluster** — API endpoint private by default; public access CIDRs configurable
- **All EKS control-plane logs** forwarded to CloudWatch Logs
- **IMDSv2 enforced** via launch template `http_tokens = "required"`
- **KMS CMK** encrypts EKS secrets, EBS volumes, S3 state bucket, DynamoDB lock table, and SNS
- **IRSA** (IAM Roles for Service Accounts) for ALB Controller, Cluster Autoscaler, EBS CSI Driver
- **Core EKS add-ons**: `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`, `eks-pod-identity-agent`
- **VPC Flow Logs** to CloudWatch
- **NAT Gateways** per AZ for high-availability egress
- **CloudWatch alarms** for CPU and memory with SNS email alerting
- **GuardDuty** with EKS runtime threat detection, Kubernetes audit logs, and malware protection
- **AWS Config** EKS compliance rules (optional)
- **S3 state bucket** with versioning, lifecycle rules, KMS encryption, and public-access block
- **DynamoDB lock table** with point-in-time recovery and KMS encryption
- **Input validation** on all variables (CIDR format, name patterns, environment, numeric ranges)
- **Dependabot** for Go modules, GitHub Actions, and Terraform providers
- **CI/CD** via GitHub Actions (`fmt`, `validate`, `tflint`, `checkov`, `go vet`, unit tests)
- **Pre-commit hooks** for local quality gates
- **terraform-docs** configuration for auto-generated documentation
- **Terratest** with golden-file methodology for 100% plan coverage

## Structure

```
.
├── .github/
│   ├── dependabot.yml              # Dependabot: Go, Actions, Terraform
│   └── workflows/
│       ├── ci.yml                  # CI: lint, validate, checkov, go test
│       └── integration.yml         # Integration tests (manual/nightly)
├── .pre-commit-config.yaml         # Pre-commit hooks
├── .terraform-docs.yml             # terraform-docs config
├── .tflint.hcl                     # tflint config with AWS plugin
├── CONTRIBUTING.md                 # Development guide
├── Makefile                        # Common operations
├── modules/
│   ├── networking/                 # VPC, subnets, IGW, NAT, flow logs
│   ├── iam/                        # Cluster/node roles, OIDC, IRSA
│   ├── eks/                        # Cluster, node groups, add-ons
│   ├── kms/                        # Customer-managed KMS key
│   ├── monitoring/                 # CloudWatch alarms, SNS, dashboard
│   ├── security/                   # GuardDuty, AWS Config
│   ├── statebucket/                # S3 state bucket + DynamoDB lock
│   └── kubernetes/                 # Namespaces, gp3 StorageClass
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars
├── tf/                             # Root Terraform configuration
│   ├── main.tf                     # Provider config, backend
│   ├── modules.tf                  # Module wiring
│   ├── variables.tf                # All input variables
│   ├── outputs.tf                  # All outputs
│   └── terraform.tfvars.example   # Example variable values
└── test/                           # Terratest suite
    ├── doc.go                      # Package documentation
    ├── main_test.go                # TestMain + shared helpers
    ├── eks_unit_test.go            # Unit tests (plan-only, golden files)
    ├── eks_integration_test.go     # Integration tests (real AWS)
    ├── modules_test.go             # Per-module unit tests
    ├── testdata/golden/            # Golden assertion files
    ├── go.mod
    ├── go.sum
    └── .golangci.yml
```

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Terraform | ≥ 1.9 |
| Go | ≥ 1.22 |
| AWS CLI | ≥ 2 |
| tflint | ≥ 0.53 |
| checkov | ≥ 3 |

### 1. Bootstrap the State Bucket

The S3 state bucket and DynamoDB lock table must exist **before** you configure
the Terraform backend. Bootstrap them locally first:

```bash
cd tf
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values

# Target only the bootstrap resources
terraform init -backend=false
terraform apply -target=module.kms -target=module.statebucket
```

### 2. Configure the Backend

Uncomment and populate the `backend "s3" {}` block in [`tf/main.tf`](tf/main.tf),
then migrate the state:

```bash
terraform init   # will prompt to migrate local state to S3
```

### 3. Deploy the Cluster

```bash
terraform plan
terraform apply
```

### 4. Configure kubectl

The `configure_kubectl` Terraform output gives you the exact command:

```bash
terraform output -raw configure_kubectl | bash
```

## Environments

Apply a specific environment by passing its `terraform.tfvars`:

```bash
cd tf
terraform apply -var-file=../environments/dev/terraform.tfvars
```

| Environment | Capacity | Endpoint |
|-------------|----------|---------|
| dev | SPOT, 1–5 nodes | Public |
| staging | ON_DEMAND, 2–8 nodes | Private |
| prod | ON_DEMAND (m5.xlarge), 3–20 nodes | Private |

## Running Tests

```bash
# Unit tests — no AWS credentials required, runs in ~60 seconds
make test-unit

# Update golden files after intentional plan changes
make test-update-golden

# Integration tests — requires AWS credentials, ~30 min
make test-integration
```

See [`test/README.md`](test/README.md) for full test documentation.

## CI/CD

| Job | Trigger | Description |
|-----|---------|-------------|
| `terraform-lint` | push/PR to main | `terraform fmt`, `validate`, `tflint` |
| `checkov` | push/PR to main | Security scan |
| `go-test` | push/PR to main | `go vet` + unit tests |
| `golangci-lint` | push/PR to main | Go linting |
| `integration` | manual / nightly | Full deploy + destroy |

## Security Best Practices Implemented

- ✅ EKS API endpoint is **private** by default
- ✅ All EKS secrets encrypted with **KMS CMK**
- ✅ All EBS volumes encrypted with **KMS CMK** via launch templates
- ✅ **IMDSv2** enforced on all nodes (`http_tokens = "required"`)
- ✅ **VPC Flow Logs** enabled for network visibility
- ✅ **GuardDuty** with EKS runtime protection
- ✅ **IRSA** instead of node-level instance profiles
- ✅ Nodes placed in **private subnets only**
- ✅ System node group **tainted** (`CriticalAddonsOnly=true:NoSchedule`)
- ✅ All S3 buckets have public-access block enabled
- ✅ Terraform state encrypted at rest in S3 with KMS

## License

[MIT](LICENSE)
