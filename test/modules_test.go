package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestUnitNetworkingModule tests the networking module in isolation by
// pointing Terraform at the module directory directly.
func TestUnitNetworkingModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/networking",
		Vars: map[string]interface{}{
			"cluster_name":            "test-net",
			"vpc_cidr":                "10.50.0.0/16",
			"availability_zones":      []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":     []string{"10.50.1.0/24", "10.50.2.0/24"},
			"private_subnet_cidrs":    []string{"10.50.11.0/24", "10.50.12.0/24"},
			"flow_log_retention_days": 30,
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "networking module plan must succeed")
}

// TestUnitKMSModule tests the KMS module in isolation.
func TestUnitKMSModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/kms",
		Vars: map[string]interface{}{
			"cluster_name":            "test-kms",
			"deletion_window_in_days": 7,
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "kms module plan must succeed")
}

// TestUnitStateBucketModule tests the statebucket module in isolation.
func TestUnitStateBucketModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/statebucket",
		Vars: map[string]interface{}{
			"bucket_name":      "test-eks-tf-state-123",
			"lock_table_name":  "test-eks-lock",
			"kms_key_arn":      "arn:aws:kms:us-east-1:123456789012:key/test-key-id",
			"access_log_bucket": "",
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "statebucket module plan must succeed")
}

// TestUnitMonitoringModule tests the monitoring module in isolation.
func TestUnitMonitoringModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/monitoring",
		Vars: map[string]interface{}{
			"cluster_name":           "test-mon",
			"enable_alerting":        false,
			"alert_email":            "",
			"kms_key_arn":            "arn:aws:kms:us-east-1:123456789012:key/test-key-id",
			"cpu_alarm_threshold":    80,
			"memory_alarm_threshold": 80,
			"log_retention_days":     30,
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "monitoring module plan must succeed")
}

// TestUnitSecurityModule tests the security module in isolation.
func TestUnitSecurityModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/security",
		Vars: map[string]interface{}{
			"cluster_name":      "test-sec",
			"enable_guardduty":  false,
			"enable_aws_config": false,
			"config_s3_bucket":  "",
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "security module plan must succeed")
}

// TestUnitNetworkingMinAZValidation asserts the networking module rejects < 2 AZs.
func TestUnitNetworkingMinAZValidation(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/networking",
		Vars: map[string]interface{}{
			"cluster_name":         "test-net",
			"vpc_cidr":             "10.50.0.0/16",
			"availability_zones":   []string{"us-east-1a"},
			"public_subnet_cidrs":  []string{"10.50.1.0/24"},
			"private_subnet_cidrs": []string{"10.50.11.0/24"},
		},
		NoColor: true,
	}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "networking module must reject fewer than 2 AZs")
}

// TestUnitKMSDeletionWindowBounds verifies KMS deletion window validation.
func TestUnitKMSDeletionWindowBounds(t *testing.T) {
	t.Parallel()

	for _, tc := range []struct {
		name    string
		days    int
		wantErr bool
	}{
		{"below_min", 6, true},
		{"at_min", 7, false},
		{"above_max", 31, true},
		{"at_max", 30, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			opts := &terraform.Options{
				TerraformDir: "../modules/kms",
				Vars: map[string]interface{}{
					"cluster_name":            "test-kms",
					"deletion_window_in_days": tc.days,
				},
				NoColor: true,
			}

			exitCode := terraform.InitAndPlanWithExitCode(t, opts)
			if tc.wantErr {
				assert.NotEqual(t, 0, exitCode)
			} else {
				assert.Equal(t, 0, exitCode)
			}
		})
	}
}

// TestUnitOutputNamesContainRequired checks that the root module plan exposes
// a required set of output names.
func TestUnitOutputNamesContainRequired(t *testing.T) {
	t.Parallel()

	required := []string{
		"cluster_name",
		"cluster_endpoint",
		"cluster_version",
		"cluster_oidc_issuer_url",
		"vpc_id",
		"private_subnet_ids",
		"public_subnet_ids",
		"configure_kubectl",
	}

	opts := defaultTerraformOptions(t)
	planStruct := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)
	require.NotNil(t, planStruct)

	for _, name := range required {
		_, ok := planStruct.RawPlan.PlannedValues.Outputs[name]
		assert.True(t, ok, "expected output %q to be present in plan", name)
	}
}

// TestUnitConfigureKubectlOutput verifies the configure_kubectl output
// contains the correct CLI command.
func TestUnitConfigureKubectlOutput(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	planJSON := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)
	require.NotNil(t, planJSON)

	output, ok := planJSON.RawPlan.PlannedValues.Outputs["configure_kubectl"]
	require.True(t, ok, "configure_kubectl output must be present")

	val, ok := output.Value.(string)
	require.True(t, ok, "configure_kubectl must be a string")
	assert.True(t, strings.HasPrefix(val, "aws eks update-kubeconfig"),
		"configure_kubectl must start with 'aws eks update-kubeconfig', got: %q", val)
}
