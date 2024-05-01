# Create security group for Flink
resource "aws_security_group" "flink_sg" {
  name        = "flink_sg"
  description = "Security group for Flink"

  # Allow inbound traffic from Kafka security group on Kafka port
  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.kafka_sg.id]
  }

  # Allow inbound SSH traffic for administration purposes (optional)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict as per your requirements
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "flink_instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.flink_sg.name]

  key_name = "realtime"

  user_data = <<-EOF
    #!/bin/bash
    # Install Java
    sudo yum update -y
    sudo yum install -y java-1.8.0-openjdk-devel
    
    # Install Flink
    wget https://downloads.apache.org/flink/flink-1.14.0/flink-1.14.0-bin-scala_2.12.tgz
    tar -xzf flink-1.14.0-bin-scala_2.12.tgz
    cd flink-1.14.0
    
    # Start Flink cluster (this is just an example, you may need to modify it based on your Flink setup)
    ./bin/start-cluster.sh
  EOF

  tags = {
    Name = "Flink Instance"
  }
}
