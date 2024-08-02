# resource "aws_instance" "mongodb_instance" {
#   instance_type = "t2.micro"     # Choose instance type according to your requirements
#   ami             = data.aws_ami.ubuntu.id

#   tags = {
#     Name = "MongoDBInstance"
#     environment = "dev"
#   }

#   # Example: Define your security group here or reference an existing one
#   security_groups = [aws_security_group.sg_mongo.name]

#   # Example: Define your key pair for SSH access
#   key_name = "realtime"

#   # Example: Define the user data to install MongoDB on launch
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo yum update -y
#               sudo yum install -y mongodb-org
#               sudo service mongod start
#               EOF
# }

# resource "aws_security_group" "sg_mongo" {
#   vpc_id = aws_vpc.vpc.id
# }
