data "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"  # Ensure this matches the actual role name in your account
}

resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = data.aws_iam_role.eks_cluster.arn  # If using existing role

  vpc_config {
    subnet_ids = [
      "subnet-0bce4f4dd294a79ce",
      "subnet-037fcf967ac2c0f75",
      "subnet-02096d6ed83530ade"
    ]
  }
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b4c8f48d3d6e50e26"]
  url             = aws_eks_cluster.example.identity[0].oidc.issuer  # Correct access to the first item
}

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "AmazonEKS_EBS_CSI_Driver_Policy"
  description = "Policy for EBS CSI Driver to manage EBS volumes"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.example.identity[0].oidc.issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ebs_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}
