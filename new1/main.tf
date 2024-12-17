provider "aws" {
  region = "us-east-1"
}

# EKS Cluster
resource "aws_eks_cluster" "example" {
  name     = "example"
  version  = "1.31"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids         = ["subnet-0bce4f4dd294a79ce", "subnet-037fcf967ac2c0f75", "subnet-02096d6ed83530ade"]
    security_group_ids = ["sg-038884b35a5e87ac5"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_service_policy
  ]
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach EKS Cluster Policies
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "node" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Policies to Node Role
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Node Group
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = ["subnet-0bce4f4dd294a79ce", "subnet-037fcf967ac2c0f75", "subnet-02096d6ed83530ade"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  tags = {
    Name = "example-node-group"
  }
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.example.token
}

data "aws_eks_cluster_auth" "example" {
  name = aws_eks_cluster.example.name
}

data "aws_eks_cluster" "example" {
  name = aws_eks_cluster.example.name
}

# Auth ConfigMap for Users and Node Groups
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML
    mapUsers = <<YAML
- userarn: arn:aws:iam::058264520519:user/pralaya
  username: pralaya
  groups:
    - system:masters
YAML
  }
}

# EKS Admin Policy for Full Access
resource "aws_iam_policy" "eks_admin_policy" {
  name        = "eks-admin-policy"
  description = "Policy for full access to EKS resources"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "eks:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "ec2:*",
        Resource = "*"
      }
    ]
  })
}

# Attach Admin Policy to Cluster and Node Roles
resource "aws_iam_policy_attachment" "eks_admin_policy_attachment" {
  name       = "eks-admin-policy-attachment"
  policy_arn = aws_iam_policy.eks_admin_policy.arn
  roles      = [aws_iam_role.cluster.name, aws_iam_role.node.name]
}
