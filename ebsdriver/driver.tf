provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster" "cluster" {
  name = "example"
}

data "aws_eks_cluster_auth" "example" {
  name = "example"
}
# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.example.token # Corrected name here
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.example.token # Corrected name here
}

# IAM Role for the EKS cluster
data "aws_iam_role" "cluster" {
  name = "eks-cluster-role"
}

# Module for AWS EBS CSI Driver resources
module "aws_ebs_csi_driver_resources" {
  source                 = "github.com/andreswebs/terraform-aws-eks-ebs-csi-driver//modules/resources"
  cluster_name           = "example"
  iam_role_arn           = data.aws_iam_role.cluster.arn
  helm_force_update      = true
  k8s_namespace          = "kube-system"
  helm_dependency_update = true
}


resource "kubernetes_storage_class" "gp2" {
  metadata {
    name = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"  # Optional, set to true if you want it as the default storage class
    }
  }

  storage_provisioner = "kubernetes.io/aws-ebs"  # Correct argument for provisioner
  parameters = {
    type   = "gp2"   # The EBS volume type (gp2 is the default)
    fsType = "ext4"  # The file system type for the volume
  }

  reclaim_policy      = "Retain"  # You can also use "Delete" if you want the volume deleted when the PVC is deleted
  volume_binding_mode = "WaitForFirstConsumer"
}