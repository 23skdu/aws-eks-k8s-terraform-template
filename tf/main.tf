##############################################################################
# tf/main.tf
# Root Terraform configuration: provider setup and backend.
##############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }

  # Uncomment and populate after bootstrapping the state bucket via modules/statebucket
  # backend "s3" {
  #   bucket         = "<your-state-bucket-name>"
  #   key            = "eks/<your-cluster-name>/terraform.tfstate"
  #   region         = "<your-aws-region>"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

provider "tls" {}

# ── Locals ─────────────────────────────────────────────────────────────────────

locals {
  common_tags = merge(var.tags, {
    Project     = var.cluster_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
