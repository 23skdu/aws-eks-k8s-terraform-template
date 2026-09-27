package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestMain is the entry point for the test suite. It performs any required
// global setup (e.g., ensuring test data directories exist) before delegating
// to the standard testing framework via m.Run().
func TestMain(m *testing.M) {
	// Ensure the golden-file directory exists before any test runs.
	if err := os.MkdirAll("testdata/golden", 0o750); err != nil {
		panic("failed to create testdata/golden directory: " + err.Error())
	}

	os.Exit(m.Run())
}

// defaultTerraformOptions returns a base *terraform.Options suitable for
// plan-only (no-op) tests that do not require real AWS credentials.
// AWS provider calls are skipped by setting TF_CLI_ARGS or mock vars as needed.
func defaultTerraformOptions(t *testing.T) *terraform.Options {
	t.Helper()

	return &terraform.Options{
		TerraformDir: "../tf",
		Vars: map[string]interface{}{
			"aws_region":             "us-east-1",
			"cluster_name":           "test-eks",
			"environment":            "test",
			"state_bucket_name":      "test-eks-tf-state",
			"state_lock_table_name":  "test-eks-lock",
			"vpc_cidr":               "10.0.0.0/16",
			"availability_zones":     []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":    []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":   []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kubernetes_version":     "1.31",
			"endpoint_public_access": false,
			"general_instance_types": []string{"t3.medium"},
			"general_capacity_type":  "ON_DEMAND",
			"general_desired_size":   2,
			"general_min_size":       1,
			"general_max_size":       10,
			"general_disk_size_gb":   50,
			"system_instance_types":  []string{"t3.small"},
			"system_desired_size":    2,
			"system_min_size":        1,
			"system_max_size":        5,
			"system_disk_size_gb":    50,
			"namespaces":             []string{"dev", "staging"},
			"enable_alerting":        false,
			"alert_email":            "",
			"enable_guardduty":       false,
			"enable_aws_config":      false,
		},
		// Disable colour output for deterministic golden-file diffs.
		NoColor: true,
		// Never use an existing workspace; always start clean.
		EnvVars: map[string]string{
			"TF_IN_AUTOMATION": "true",
		},
	}
}
