##############################################################################
# Makefile
# Common operations for the aws-eks-k8s-terraform-template.
##############################################################################

.DEFAULT_GOAL := help
TERRAFORM_DIR := tf
TEST_DIR      := test

.PHONY: help fmt validate lint checkov plan apply destroy \
        test-unit test-integration test-update-golden \
        go-vet go-lint pre-commit-install

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}'

# ── Terraform ─────────────────────────────────────────────────────────────────

fmt: ## Format all Terraform files
	terraform fmt -recursive

validate: ## Validate the root module and all child modules
	@echo "=== Validating tf/ ==="
	cd $(TERRAFORM_DIR) && terraform init -backend=false && terraform validate
	@for module in modules/*/; do \
		echo "=== Validating $$module ==="; \
		cd "$$module" && terraform init -backend=false 2>/dev/null || true; \
		terraform validate; \
		cd -; \
	done

lint: ## Run tflint on the root module
	cd $(TERRAFORM_DIR) && tflint --init && tflint

checkov: ## Run Checkov security scan
	checkov -d . --framework terraform \
		--skip-check CKV_AWS_79,CKV2_AWS_38,CKV2_AWS_39

plan: ## Run terraform plan (requires AWS credentials + terraform.tfvars)
	cd $(TERRAFORM_DIR) && terraform init && terraform plan

apply: ## Run terraform apply (requires AWS credentials + terraform.tfvars)
	cd $(TERRAFORM_DIR) && terraform init && terraform apply

destroy: ## Destroy all Terraform-managed resources
	cd $(TERRAFORM_DIR) && terraform destroy

# ── Go / Tests ────────────────────────────────────────────────────────────────

go-vet: ## Run go vet on the test suite
	cd $(TEST_DIR) && go vet ./...

go-lint: ## Run golangci-lint on the test suite
	cd $(TEST_DIR) && golangci-lint run --config .golangci.yml

test-unit: ## Run unit tests (plan-only, but still needs valid AWS credentials)
	cd $(TEST_DIR) && go test -v -count=1 -timeout 15m -run TestUnit ./...

test-race: ## Run unit tests under the race detector
	cd $(TEST_DIR) && go test -race -count=1 -timeout 15m -run TestUnit ./...

test-modules: ## Run per-module unit tests
	cd $(TEST_DIR) && go test -v -count=1 -timeout 15m -run TestUnitNetworking,TestUnitKMS,TestUnitStateBucket,TestUnitMonitoring,TestUnitSecurity ./...

test-integration: ## Run integration tests (requires AWS credentials)
	cd $(TEST_DIR) && go test -v -count=1 -timeout 90m -run TestIntegration ./...

test-update-golden: ## Regenerate golden test data files
	cd $(TEST_DIR) && UPDATE_GOLDEN=true go test -v -count=1 -timeout 15m -run TestUnit ./...

# ── Pre-commit ────────────────────────────────────────────────────────────────

pre-commit-install: ## Install pre-commit hooks
	pre-commit install

pre-commit-run: ## Run all pre-commit hooks against all files
	pre-commit run --all-files
