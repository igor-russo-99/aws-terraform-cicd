# Create security group for Kafka
resource "aws_security_group" "kafka_sg" {
  name        = "kafka_sg"
  description = "Security group for Kafka"

  # Allow inbound traffic on Kafka port (default 9092)
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as per your network requirements
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define EC2 instances for Kafka 
resource "aws_instance" "kafka_instance" {
  ami             = data.aws_ami.ubuntu
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.kafka_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    # Install Java
    sudo yum update -y
    sudo yum install -y java-1.8.0-openjdk-devel
    
    # Install Kafka
    wget https://downloads.apache.org/kafka/2.8.1/kafka_2.13-2.8.1.tgz
    tar -xzf kafka_2.13-2.8.1.tgz
    cd kafka_2.13-2.8.1
    
    # Start Kafka server (this is just an example, you may need to modify it based on your Kafka setup)
    nohup bin/kafka-server-start.sh config/server.properties > kafka.log 2>&1 &
  EOF

  tags = {
    Name = "Kafka Instance"
  }
}
