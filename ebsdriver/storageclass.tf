# # Create a default StorageClass for the EBS CSI driver
# resource "kubernetes_storage_class_v1" "ebs_sc" {
#   metadata {
#     name = "gp2"
#   }

#   storage_provisioner = "ebs.csi.aws.com"

#   parameters = {
#     type = "gp2"
#   }

#   volume_binding_mode = "WaitForFirstConsumer"
# }
