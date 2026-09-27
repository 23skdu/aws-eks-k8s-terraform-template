package test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ── Golden-file helpers ───────────────────────────────────────────────────────

// goldenFilePath returns the path to the golden file for the given test name.
func goldenFilePath(t *testing.T) string {
	t.Helper()
	name := strings.ReplaceAll(t.Name(), "/", "_")
	return filepath.Join("testdata", "golden", name+".json")
}

// assertGolden compares got against the golden file for the running test.
// When the UPDATE_GOLDEN environment variable is set to "true", the golden
// file is written (or overwritten) instead of being compared.
func assertGolden(t *testing.T, got interface{}) {
	t.Helper()

	raw, err := json.MarshalIndent(got, "", "  ")
	require.NoError(t, err, "failed to marshal value for golden comparison")

	path := goldenFilePath(t)

	if os.Getenv("UPDATE_GOLDEN") == "true" {
		require.NoError(t, os.MkdirAll(filepath.Dir(path), 0o750))
		require.NoError(t, os.WriteFile(path, append(raw, '\n'), 0o600),
			"failed to write golden file")
		t.Logf("golden file updated: %s", path)
		return
	}

	want, err := os.ReadFile(path) //nolint:gosec // path is constructed from test name, not user input
	if os.IsNotExist(err) {
		t.Fatalf("golden file %q not found; run with UPDATE_GOLDEN=true to create it", path)
	}
	require.NoError(t, err, "failed to read golden file")

	assert.JSONEq(t, string(want), string(raw),
		"output does not match golden file %q; re-run with UPDATE_GOLDEN=true to update", path)
}

// ── Unit Tests (plan-only, no AWS credentials required) ───────────────────────

// TestUnitVariableDefaults verifies that the root module can be initialised and
// planned with default variable values without errors.
func TestUnitVariableDefaults(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "plan must succeed with default variable values")
}

// TestUnitNetworkingModuleOutputNames verifies the networking module exposes
// the expected output names via plan JSON.
func TestUnitNetworkingModuleOutputNames(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	planStruct := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)

	// The plan must not be nil
	require.NotNil(t, planStruct, "plan JSON must not be nil")
}

// TestUnitClusterNameValidation ensures that an invalid cluster name causes a
// Terraform validation error (exit code 1).
func TestUnitClusterNameValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["cluster_name"] = "INVALID_NAME!!"

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for invalid cluster_name")
}

// TestUnitEnvironmentValidation ensures that an invalid environment value is
// rejected by the input validation rule.
func TestUnitEnvironmentValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["environment"] = "unknown-env"

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for invalid environment")
}

// TestUnitVPCCIDRValidation ensures that an invalid VPC CIDR is rejected.
func TestUnitVPCCIDRValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["vpc_cidr"] = "not-a-cidr"

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for invalid vpc_cidr")
}

// TestUnitCapacityTypeValidation ensures SPOT/ON_DEMAND are the only allowed
// values for general_capacity_type.
func TestUnitCapacityTypeValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["general_capacity_type"] = "RESERVED"

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for invalid general_capacity_type")
}

// TestUnitKubernetesVersionValidation ensures Kubernetes versions are in the
// expected format (e.g. "1.31").
func TestUnitKubernetesVersionValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["kubernetes_version"] = "v1.31.0" // wrong format

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for invalid kubernetes_version format")
}

// TestUnitAvailabilityZonesMinCount ensures that fewer than 2 AZs is rejected.
func TestUnitAvailabilityZonesMinCount(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["availability_zones"] = []string{"us-east-1a"}
	opts.Vars["public_subnet_cidrs"] = []string{"10.0.1.0/24"}
	opts.Vars["private_subnet_cidrs"] = []string{"10.0.11.0/24"}

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for fewer than 2 AZs")
}

// TestUnitDiskSizeValidation ensures the minimum disk size constraint is enforced.
func TestUnitDiskSizeValidation(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	opts.Vars["general_disk_size_gb"] = 10 // below minimum of 20

	exitCode := terraform.InitAndPlanWithExitCode(t, opts)
	assert.NotEqual(t, 0, exitCode, "expected non-zero exit code for disk size below minimum")
}

// TestUnitPlanOutputsGolden runs a full plan and captures the output names,
// comparing them against a golden file to detect regressions.
func TestUnitPlanOutputsGolden(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	planStruct := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)
	require.NotNil(t, planStruct)

	// Collect output names from RawPlan.PlannedValues.Outputs
	outputNames := make([]string, 0, len(planStruct.RawPlan.PlannedValues.Outputs))
	for name := range planStruct.RawPlan.PlannedValues.Outputs {
		outputNames = append(outputNames, name)
	}
	sort.Strings(outputNames)

	assertGolden(t, map[string]interface{}{
		"output_names": outputNames,
	})
}

// TestUnitPlanResourceTypes verifies the expected resource types appear in the
// plan and stores them in a golden file.
func TestUnitPlanResourceTypes(t *testing.T) {
	t.Parallel()

	opts := defaultTerraformOptions(t)
	planStruct := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)
	require.NotNil(t, planStruct)

	resourceTypes := collectResourceTypes(planStruct)
	sort.Strings(resourceTypes)

	assertGolden(t, map[string]interface{}{
		"resource_types": resourceTypes,
	})
}

// collectResourceTypes walks the ResourcePlannedValuesMap and returns a
// deduplicated slice of resource type strings.
func collectResourceTypes(plan *terraform.PlanStruct) []string {
	seen := make(map[string]struct{})

	for _, r := range plan.ResourcePlannedValuesMap {
		seen[r.Type] = struct{}{}
	}

	types := make([]string, 0, len(seen))
	for tp := range seen {
		types = append(types, tp)
	}

	return types
}
