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

# Go must be >= 1.26 to match the `go` directive in test/go.mod.
# golangci-lint must be >= 2.14: test/.golangci.yml uses the v2 schema,
# and CI (golangci-lint-action@v9) pins v2.14.0 to match.

# 2. Install pre-commit hooks
make pre-commit-install

# 3. Verify everything is working
make fmt validate lint
```

> `make validate` currently **fails** on the root module with a
> `module.eks` ↔ `module.iam` dependency cycle. This is a pre-existing bug, not
> something you introduced — see the Known Issues section of the
> [README](README.md). All eight child modules validate cleanly.

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
- Use Terratest's `*Context` helpers and pass `t.Context()`. The non-context
  variants are deprecated as of terratest v1.0 and `SA1019` will flag them.
- Unit tests need valid AWS credentials even though they only plan — the AWS
  provider calls `sts:GetCallerIdentity` to resolve the account ID.

### Providers

- Provider version constraints are declared in **both** the root module and,
  where a child module declares its own `required_providers`, in that child
  module. Terraform intersects all of them, so mismatched pins across a major
  version boundary make `terraform init` fail with
  `no available releases match the given constraints`.
- Dependabot only rewrites the root declaration, so provider-major PRs against
  this repo need the matching child-module edit by hand. Today
  `modules/kubernetes` is the only child module with its own pin.
- Commit the root `tf/.terraform.lock.hcl` so the validated provider builds are
  reproducible. Child-module lock files are gitignored on purpose.

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

All resources are automatically destroyed via
`defer terraform.DestroyContext(...)`, even if the test fails.

## Useful First Contributions

The [Known Issues](README.md#known-issues) list in the README is the best
guide. In rough order of tractability:

1. Migrate `test/eks_integration_test.go` from end-of-support `aws-sdk-go` v1
   to `aws-sdk-go-v2` (five helpers, self-contained).
2. Break the `module.eks` ↔ `module.iam` cycle so the template can plan.
3. Unblock the `go-test` CI job by giving the test suite a way to skip AWS
   credential validation.
