package test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// integrationTerraformOptions returns Terraform options for integration tests
// that deploy real resources. A unique suffix is used to avoid name collisions
// between parallel test runs.
func integrationTerraformOptions(t *testing.T, uniqueID string) *terraform.Options {
	t.Helper()

	clusterName := fmt.Sprintf("test-eks-%s", uniqueID)
	bucketName := fmt.Sprintf("test-eks-tf-state-%s", uniqueID)

	return &terraform.Options{
		TerraformDir: "../tf",
		Vars: map[string]interface{}{
			"aws_region":             "us-east-1",
			"cluster_name":           clusterName,
			"environment":            "test",
			"state_bucket_name":      bucketName,
			"state_lock_table_name":  fmt.Sprintf("test-eks-lock-%s", uniqueID),
			"vpc_cidr":               "10.100.0.0/16",
			"availability_zones":     []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":    []string{"10.100.1.0/24", "10.100.2.0/24"},
			"private_subnet_cidrs":   []string{"10.100.11.0/24", "10.100.12.0/24"},
			"kubernetes_version":     "1.31",
			"endpoint_public_access": true,
			"public_access_cidrs":    []string{"0.0.0.0/0"},
			"general_instance_types": []string{"t3.medium"},
			"general_capacity_type":  "ON_DEMAND",
			"general_desired_size":   1,
			"general_min_size":       1,
			"general_max_size":       3,
			"general_disk_size_gb":   50,
			"system_instance_types":  []string{"t3.small"},
			"system_desired_size":    1,
			"system_min_size":        1,
			"system_max_size":        2,
			"system_disk_size_gb":    50,
			"namespaces":             []string{"test"},
			"enable_alerting":        false,
			"alert_email":            "",
			"enable_guardduty":       false,
			"enable_aws_config":      false,
		},
		NoColor: true,
		EnvVars: map[string]string{
			"TF_IN_AUTOMATION": "true",
		},
	}
}

// newAWSSession creates an AWS session for the given region.
func newAWSSession(t *testing.T, region string) *session.Session {
	t.Helper()
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	require.NoError(t, err, "failed to create AWS session")
	return sess
}

// getEKSCluster returns the EKS cluster description or fails the test.
func getEKSCluster(t *testing.T, sess *session.Session, clusterName string) *eks.Cluster {
	t.Helper()
	svc := eks.New(sess)
	out, err := svc.DescribeClusterWithContext(context.Background(), &eks.DescribeClusterInput{
		Name: aws.String(clusterName),
	})
	require.NoError(t, err, "failed to describe EKS cluster %q", clusterName)
	return out.Cluster
}

// getVPC returns the VPC by its ID or fails the test.
func getVPC(t *testing.T, sess *session.Session, vpcID string) *ec2.Vpc {
	t.Helper()
	svc := ec2.New(sess)
	out, err := svc.DescribeVpcsWithContext(context.Background(), &ec2.DescribeVpcsInput{
		VpcIds: []*string{aws.String(vpcID)},
	})
	require.NoError(t, err, "failed to describe VPC %q", vpcID)
	require.NotEmpty(t, out.Vpcs, "VPC %q not found", vpcID)
	return out.Vpcs[0]
}

// TestIntegrationEKSCluster deploys a real EKS cluster, asserts key
// properties, and tears it down. This test is gated behind the -run flag
// "TestIntegration" and requires real AWS credentials.
//
// Expected runtime: ~25-30 minutes.
func TestIntegrationEKSCluster(t *testing.T) {
	// Do NOT call t.Parallel() here; integration tests consume real quota.

	uniqueID := strings.ToLower(random.UniqueID())
	awsRegion := "us-east-1"
	opts := integrationTerraformOptions(t, uniqueID)
	ctx := t.Context()

	// Always clean up, even if the test panics.
	defer terraform.DestroyContext(t, ctx, opts)

	// Deploy
	terraform.InitAndApplyContext(t, ctx, opts)

	// ── Assert outputs ──────────────────────────────────────────────────────

	clusterName := terraform.OutputContext(t, ctx, opts, "cluster_name")
	assert.Equal(t, fmt.Sprintf("test-eks-%s", uniqueID), clusterName)

	clusterVersion := terraform.OutputContext(t, ctx, opts, "cluster_version")
	assert.Equal(t, "1.31", clusterVersion)

	vpcID := terraform.OutputContext(t, ctx, opts, "vpc_id")
	assert.NotEmpty(t, vpcID, "vpc_id output must not be empty")

	configureCmd := terraform.OutputContext(t, ctx, opts, "configure_kubectl")
	assert.Contains(t, configureCmd, "aws eks update-kubeconfig")

	// ── Assert real AWS resources via SDK ─────────────────────────────────

	sess := newAWSSession(t, awsRegion)

	// VPC exists and has correct CIDR
	vpc := getVPC(t, sess, vpcID)
	assert.Equal(t, "10.100.0.0/16", aws.StringValue(vpc.CidrBlock))

	// EKS cluster is ACTIVE
	cluster := getEKSCluster(t, sess, clusterName)
	assert.Equal(t, "ACTIVE", aws.StringValue(cluster.Status))

	// Secrets are encrypted (encryption config present)
	assert.NotEmpty(t, cluster.EncryptionConfig,
		"EKS secrets must be encrypted with KMS CMK")

	// Endpoint public access is true (set above for test convenience)
	require.NotNil(t, cluster.ResourcesVpcConfig)
	assert.True(t, aws.BoolValue(cluster.ResourcesVpcConfig.EndpointPublicAccess))

	// ── Retry-based check: node group becomes ACTIVE ──────────────────────

	eksSvc := eks.New(sess)
	ngName := fmt.Sprintf("%s-general", clusterName)

	retry.DoWithRetryContext(t, ctx, "Wait for general node group to become ACTIVE",
		40, 30*time.Second,
		func() (string, error) {
			out, err := eksSvc.DescribeNodegroupWithContext(ctx,
				&eks.DescribeNodegroupInput{
					ClusterName:   aws.String(clusterName),
					NodegroupName: aws.String(ngName),
				})
			if err != nil {
				return "", fmt.Errorf("DescribeNodegroup error: %w", err)
			}
			status := aws.StringValue(out.Nodegroup.Status)
			if status != "ACTIVE" {
				return "", fmt.Errorf("node group status: %s", status)
			}
			return status, nil
		})
}
