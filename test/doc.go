// Package test contains Terratest-based integration and unit tests for the
// AWS EKS Kubernetes Terraform template.
//
// Tests use the "golden file" methodology: expected Terraform plan output is
// stored in testdata/golden/ and compared on each run. Update golden files by
// running tests with the UPDATE_GOLDEN=true environment variable.
//
// # Running Tests
//
// Unit tests (plan only, but still require valid AWS credentials — the AWS
// provider resolves the account ID during plan via sts:GetCallerIdentity):
//
//	go test -v -run TestUnit ./...
//
// Integration tests (requires real AWS credentials with permissions to create
// EKS, VPC, IAM, KMS, and S3 resources):
//
//	go test -v -timeout 60m -run TestIntegration ./...
//
// Update golden files:
//
//	UPDATE_GOLDEN=true go test -v -run TestUnit ./...
package test
