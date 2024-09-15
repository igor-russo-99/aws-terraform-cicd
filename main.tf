
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {

    bucket         = "igorsr-dev-terraform-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-bucket-kms-key"
    dynamodb_table = "terraform-state"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# resource "aws_instance" "example_ec2_instance" {
#   ami = data.aws_ami.ubuntu.id
#   # security_groups = [aws_security_group.sg.id]
#   instance_type = "t3.micro"
#   key_name      = "realtime"
#   tags = {
#     Name = "HelloWorld"
#   }
# }
