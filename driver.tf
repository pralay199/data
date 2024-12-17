provider "aws" {
  region = "us-east-1"  # Specify the region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  token                  = data.aws_eks_cluster_auth.example.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
}

data "aws_eks_cluster" "example" {
  name = "example"  # Replace with your actual EKS cluster name
}

data "aws_eks_cluster_auth" "example" {
  name = data.aws_eks_cluster.example.name
}

# Create the custom IAM policy for EBS CSI driver
resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "EBSCSIDriverPolicy"
  description = "Custom policy for EBS CSI driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeKeyPairs"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the custom policy to the EKS node IAM role
resource "aws_iam_role_policy_attachment" "eks_nodes_ebs_policy" {
  role       = "eks-node-role"  # Reference to the IAM role by name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn  # Reference to the IAM policy ARN
}


# Kubernetes Cluster Role Binding for EBS CSI driver
resource "kubernetes_cluster_role_binding" "ebs_csi_driver" {
  metadata {
    name = "ebs-csi-driver-node-access"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa" # Replace with the service account name of the EBS CSI driver
    namespace = "kube-system"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = "system:node"  # This grants access to nodes
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "ebs_csi_controller" {
  metadata {
    name = "ebs-csi-controller-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "create", "delete", "watch", "list", "update"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get", "watch", "list", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "ebs_csi_controller_binding" {
  metadata {
    name = "ebs-csi-controller-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"  # Replace with your service account name
    namespace = "kube-system"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.ebs_csi_controller.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}


# Apply the Kubernetes manifests for the EBS CSI driver
resource "kubernetes_manifest" "ebs_csi_driver" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata   = {
      name      = "ebs-csi-controller"
      namespace = "kube-system"
    }
    spec       = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "ebs-csi-controller"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "ebs-csi-controller"
          }
        }
        spec = {
          containers = [
            {
              name  = "ebs-csi-controller"
              image = "amazon/aws-ebs-csi-driver:v1.3.0"
              ports = [
                {
                  containerPort = 443
                }
              ]
              env = [
                {
                  name = "CSI_NODE_NAME"
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "spec.nodeName"
                    }
                  }
                }
              ]
            }
          ]
        }
      }
    }
  }
}
