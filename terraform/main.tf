provider "aws" {
  region = "us-east-1" # Replace with your desired region
}



# resource "aws_instance" "example" {
#   ami           = "ami-0453ec754f44f9a4a" # Replace with a valid AMI ID for your region
#   instance_type = "t2.micro"

#   tags = {
#     Name = "HelloWorld"
#   }
# }

# resource "aws_s3_bucket" "example" {
#   bucket = "my-unique-bucket-pk1" # Replace with your desired bucket name


#   tags = {
#     Name        = "MyBucket"
#     Environment = "Dev"
#   }
# }


# terraform {
#   backend "s3" {
#     bucket         = "my-unique-bucket-pk1" # Replace with your bucket name
#     key            = "pralay-pk1/terraform1.tfstate" # Path inside the bucket
#     region         = "us-east-1" 
#   }
# }


provider "kubernetes" {
config_path = ""
}


provider "helm" {
  kubernetes {
    config_path = ""
  }
}

variable "replicaCount" {
  description = "Description of the variable"  # Optional
  type        = number                         # Optional (string, number, bool, list, map, object, tuple)
  default     = 1               # Optional
}

variable "pralay" {
  description = "Description of the variable"  # Optional
  type        = string                         # Optional (string, number, bool, list, map, object, tuple)
  default     = "silu"              # Optional
}

