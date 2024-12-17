# resource "tls_private_key" "rsa" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "local_file" "my_key" {
#   content  = tls_private_key.rsa.private_key_pem
#   filename = "${path.module}/my_key.pem"
# }

# resource "aws_key_pair" "deployer" {
#   key_name   = "my_key"
#   public_key = tls_private_key.rsa.public_key_openssh
# }