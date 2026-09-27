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

- **Require valid AWS credentials** — see the note below
- Fast: complete in ~60 seconds
- Cover: variable validation, plan output names, resource type coverage
- Use golden files for regression detection

```bash
go test -v -run TestUnit ./...
# or via Make:
make test-unit
```

> **Why credentials are needed for "plan-only" tests.** AWS provider v6
> resolves the account ID during `plan` by calling `sts:GetCallerIdentity`, and
> that call has to succeed before any planning happens. Placeholder credentials
> are not enough — they fail with
> `api error InvalidClientTokenId: The security token included in the request is
> invalid`. No permissions to create or modify resources are needed; being able
> to call STS is sufficient. This is why the `go-test` CI job, which runs
> without credentials, cannot currently pass.

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
- Always destroy resources via `defer terraform.DestroyContext(...)`, even on failure

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

Golden files are meant to be committed so CI can compare against them, but
**none are committed yet** — `testdata/golden/` is empty in version control, so
`TestUnitPlanOutputsGolden` and `TestUnitPlanResourceTypes` currently fail with
`golden file not found` and the CI `upload-artifact` step has nothing to
upload. Run the command above once against a real account to create them.

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

The module targets Go 1.26, set by the `go` directive in `go.mod`. CI requests
the same version via `actions/setup-go`.

Terratest v1.0.x deprecated its non-context helpers in favour of `*Context`
variants that accept a `context.Context`. The suite uses `t.Context()` so
cancellation tracks the test lifetime. Prefer the `*Context` forms in new code;
`staticcheck`'s `SA1019` check is active and will flag the old ones.

Key packages:

| Package | Purpose |
|---------|---------|
| `github.com/gruntwork-io/terratest` | Terraform test framework |
| `github.com/stretchr/testify` | Assertions (`assert`, `require`) |
| `github.com/aws/aws-sdk-go` | AWS SDK (integration tests) — **v1, end-of-support** |

`aws-sdk-go` v1 reached end-of-support on 2025-07-31. Only
`eks_integration_test.go` uses it, through five helpers. Its `SA1019`
deprecation is suppressed for that file alone until it is ported to
`aws-sdk-go-v2`; `SA1019` remains active for every other file.
