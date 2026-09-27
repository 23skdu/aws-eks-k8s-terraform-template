##############################################################################
# modules/ebs_csi_addon/main.tf
# Installs the aws-ebs-csi-driver add-on, binding it to an IRSA role.
#
# This add-on lives outside modules/eks because it needs an IRSA role, and an
# IRSA role needs the cluster's OIDC issuer URL. Keeping it here lets the
# dependency graph stay acyclic: iam -> eks -> irsa -> ebs_csi_addon.
##############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66"
    }
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = var.ebs_csi_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}
