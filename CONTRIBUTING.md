##############################################################################
# CONTRIBUTING.md
##############################################################################

# Contributing

Thank you for helping improve this template! Please read this guide before
opening a pull request.

## Development Setup

```bash
# 1. Install dependencies
brew install terraform tflint checkov golangci-lint pre-commit go

# 2. Install pre-commit hooks
make pre-commit-install

# 3. Verify everything is working
make fmt validate lint
```

## Workflow

1. **Fork** the repository and create a feature branch from `main`.
2. **Make changes** following the conventions below.
3. **Run quality gates** locally:
   ```bash
   make fmt validate lint checkov go-vet go-lint test-unit
   ```
4. **Open a pull request** — CI will run all checks automatically.

## Conventions

### Terraform

- All `variable` blocks must have a `description` and explicit `type`.
- Input validation (`validation {}`) is required for all string and numeric
  variables where a constraint is meaningful.
- Resources must carry the `tags = var.tags` (or `merge(...)`) attribute.
- Follow the module layout: `main.tf`, `variables.tf`, `outputs.tf`.

### Go / Terratest

- All new test functions must have a `t.Parallel()` call (except integration
  tests that provision real resources).
- Unit tests are prefixed `TestUnit`. Integration tests are prefixed
  `TestIntegration`.
- Golden files live in `test/testdata/golden/`. Update them with
  `make test-update-golden` when plan output legitimately changes.

### Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`.
- Reference issues in the commit body: `Closes #123`.

## Running Integration Tests

Integration tests create real AWS resources and take ~25-30 minutes. They
require:

- AWS credentials with permissions to create EKS, VPC, IAM, KMS, S3, and
  DynamoDB resources.
- The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
  set, **or** an AWS profile configured.

```bash
make test-integration
```

All resources are automatically destroyed via `defer terraform.Destroy(...)`,
even if the test fails.
