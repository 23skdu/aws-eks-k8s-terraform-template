# AWS EKS Kubernetes Terraform Template

Production-ready EKS cluster on AWS with modular architecture, multi-environment support, KMS encryption, and comprehensive Terratest coverage following the golden-file methodology.

## Features

- **8 reusable modules**: `networking`, `iam`, `eks`, `kms`, `monitoring`, `security`, `statebucket`, `kubernetes`
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

> ⚠️ **Steps 1–3 do not run end to end yet.** The root module currently fails
> `terraform validate` with a `module.eks` ↔ `module.iam` dependency cycle, so
> `plan` and `apply` cannot execute. Read
> [Known Issues](#known-issues) before following this. Step 4 is unaffected.
> Every child module validates cleanly on its own, so the individual modules
> are usable now.

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Terraform | ≥ 1.9 | CI pins 1.9.8; validated locally against 1.16.4 |
| Go | ≥ 1.26 | Must satisfy the `go` directive in [`test/go.mod`](test/go.mod) |
| golangci-lint | ≥ 2.14 | v2 schema only — see [`test/.golangci.yml`](test/.golangci.yml) |
| AWS CLI | ≥ 2 | Used for `aws eks get-token` by the Kubernetes provider |
| tflint | ≥ 0.53 | |
| checkov | ≥ 3 | |

### Provider versions

| Provider | Constraint | Locked |
|----------|-----------|--------|
| `hashicorp/aws` | `~> 6.66` | 6.66.0 |
| `hashicorp/kubernetes` | `~> 3.2` | 3.2.1 |
| `hashicorp/tls` | `~> 4.0` | 4.4.1 |

Versions are pinned in [`tf/main.tf`](tf/main.tf) and recorded in
[`tf/.terraform.lock.hcl`](tf/.terraform.lock.hcl), which is committed so the
exact provider builds this template was validated against are reproducible.

> **When bumping a provider in a child module**, update the pin in *both* the
> root module and the child module. Terraform intersects version constraints
> across every module in the configuration, so a root pin of `~> 3.2` and a
> child pin of `~> 2.32` resolve to no version at all and `terraform init` fails
> with `no available releases match the given constraints`. Dependabot only
> rewrites the root declaration, so provider-major PRs against this repo need
> the matching child-module edit. `modules/kubernetes` is the only child module
> that declares its own `required_providers` block today.

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

> **The unit tests need real AWS credentials.** They are "plan-only" in that
> nothing is provisioned, but AWS provider v6 resolves the account ID at plan
> time by calling `sts:GetCallerIdentity`. That call must succeed, so the
> credentials need to be genuinely valid — dummy values are rejected with
> `InvalidClientTokenId`. No IAM permissions to create resources are required,
> only the ability to call STS. See [Known Issues](#known-issues).

```bash
# Unit tests — requires valid AWS credentials, ~60 seconds
make test-unit

# Update golden files after intentional plan changes
make test-update-golden

# Integration tests — requires full AWS permissions, ~30 min
make test-integration
```

See [`test/README.md`](test/README.md) for full test documentation.

## Known Issues

Pre-existing problems, unrelated to any recent dependency bump. Fixing these is
the most useful next contribution to this template.

### 1. `module.eks` ↔ `module.iam` dependency cycle

`terraform validate` on the root module fails, which also blocks
`terraform plan` and `terraform apply`:

```
Error: Cycle:
  module.eks.aws_eks_cluster.main
  module.eks.var.cluster_role_arn (expand)
  module.iam.output.cluster_role_arn (expand)
  module.iam (expand)
  module.eks.output.cluster_arn (expand)
  ...
```

`module.eks` needs IAM role ARNs from `module.iam`, while `module.iam` needs
the cluster ARN, OIDC issuer URL, and cluster name from `module.eks`. The
cycle closes on the OIDC issuer: `modules/iam` derives it from the cluster
name and AWS account ID rather than reading the cluster's actual issuer.

All eight child modules validate cleanly in isolation — the cycle only exists
once they are wired together in the root module.

Because `plan` and `apply` cannot run, the Quick Start above cannot complete
end to end until this is resolved. Breaking it typically means moving the OIDC
provider creation into `module.eks` (which owns the cluster), or passing the
account ID in as an input so `module.iam` no longer needs a cluster output.

### 2. Unit tests require AWS credentials

As described above, plan-based tests cannot run without valid credentials. The
`go-test` CI job in [`ci.yml`](.github/workflows/ci.yml) sets no AWS
credentials, so it fails for this reason. Two ways to resolve it:

- Grant the job a read-only credential set via repository secrets (needs only
  `sts:GetCallerIdentity`).
- Have the test suite configure the provider to skip validation. For the root
  module this means setting `skip_credentials_validation`,
  `skip_requesting_account_id`, and `skip_metadata_api_check` on the provider
  in `tf/main.tf` behind a variable that defaults to `false`. The per-module
  tests in `modules_test.go` would need equivalent handling, since the child
  modules have no provider block of their own.

### 3. `aws-sdk-go` v1 is end-of-support

`test/eks_integration_test.go` still uses AWS SDK for Go v1, which reached
end-of-support on 2025-07-31. The `SA1019` deprecation is currently suppressed
for that file only so the rest of the deprecation checking stays active.
Migrating to `aws-sdk-go-v2` is a contained refactor (five helpers in that one
file) and is worth doing as its own change.

## CI/CD

| Job | Trigger | Description |
|-----|---------|-------------|
| `terraform-lint` | push/PR to main | `terraform fmt`, `validate`, `tflint` |
| `checkov` | push/PR to main | Security scan |
| `go-test` | push/PR to main | `go vet` + unit tests |
| `golangci-lint` | push/PR to main | Go linting |
| `integration` | manual / nightly | Full deploy + destroy |

`golangci-lint-action@v9` requires golangci-lint **v2**, so `ci.yml` pins
`v2.14.0` to match the v2 schema in `test/.golangci.yml`. The two must be
bumped together. CI requests Go 1.26 to satisfy the `go` directive in
`test/go.mod`, and Terraform 1.9.8, which is compatible with the pinned
provider versions.

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
