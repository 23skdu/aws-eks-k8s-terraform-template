# test/ — Terratest Suite

This directory contains the Terratest-based test suite for the AWS EKS
Kubernetes Terraform template. Tests follow the **golden-file methodology**:
expected plan output is stored in `testdata/golden/` and compared on each run
to catch regressions without deploying real infrastructure.

## Directory Layout

```
test/
├── doc.go                    # Package documentation
├── main_test.go              # TestMain entry point + shared helpers
├── eks_unit_test.go          # Unit tests (plan-only, golden files)
├── eks_integration_test.go   # Integration tests (real AWS deployment)
├── modules_test.go           # Per-module unit tests
├── testdata/
│   └── golden/               # Golden assertion JSON files (committed)
├── go.mod                    # Go module definition
├── go.sum                    # Dependency checksums
└── .golangci.yml             # golangci-lint configuration
```

## Test Categories

### Unit Tests (`TestUnit*`)

- **No AWS credentials required** — run entirely via `terraform plan`
- Fast: complete in ~60 seconds
- Cover: variable validation, plan output names, resource type coverage
- Use golden files for regression detection

```bash
go test -v -run TestUnit ./...
# or via Make:
make test-unit
```

### Module Unit Tests (`TestUnit<ModuleName>*`)

Each module is tested individually:

| Test | Module |
|------|--------|
| `TestUnitNetworkingModule` | `modules/networking` |
| `TestUnitKMSModule` | `modules/kms` |
| `TestUnitStateBucketModule` | `modules/statebucket` |
| `TestUnitMonitoringModule` | `modules/monitoring` |
| `TestUnitSecurityModule` | `modules/security` |

```bash
make test-modules
```

### Integration Tests (`TestIntegration*`)

- **Requires real AWS credentials** with permissions for EKS, VPC, IAM, KMS, S3
- Runtime: ~25-30 minutes per test
- Always destroy resources via `defer terraform.Destroy(...)`, even on failure

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
go test -v -timeout 90m -run TestIntegration ./...
# or via Make:
make test-integration
```

## Golden File Methodology

Golden files are JSON snapshots of Terraform plan output. They detect
unintentional changes to resource types or output structure.

### Updating Golden Files

After making an **intentional** change to the Terraform configuration:

```bash
UPDATE_GOLDEN=true go test -v -run TestUnit ./...
# or via Make:
make test-update-golden
```

Golden files are committed to version control so CI can compare against them.
A diff in CI indicates the plan changed unexpectedly — either a bug or a
missing golden-file update.

## Validation Tests

The following input validation rules are verified by unit tests:

| Test | Variable | Invalid Value |
|------|----------|--------------|
| `TestUnitClusterNameValidation` | `cluster_name` | `"INVALID_NAME!!"` |
| `TestUnitEnvironmentValidation` | `environment` | `"unknown-env"` |
| `TestUnitVPCCIDRValidation` | `vpc_cidr` | `"not-a-cidr"` |
| `TestUnitCapacityTypeValidation` | `general_capacity_type` | `"RESERVED"` |
| `TestUnitKubernetesVersionValidation` | `kubernetes_version` | `"v1.31.0"` |
| `TestUnitAvailabilityZonesMinCount` | `availability_zones` | single AZ |
| `TestUnitDiskSizeValidation` | `general_disk_size_gb` | `10` (below min) |
| `TestUnitKMSDeletionWindowBounds` | `deletion_window_in_days` | `6` and `31` |

## Dependencies

All dependencies are managed by Go modules. Update them with:

```bash
go mod tidy
```

Key packages:

| Package | Purpose |
|---------|---------|
| `github.com/gruntwork-io/terratest` | Terraform test framework |
| `github.com/stretchr/testify` | Assertions (`assert`, `require`) |
| `github.com/aws/aws-sdk-go` | AWS SDK (integration tests) |
