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

# Define EC2 instances for Kafka 
resource "aws_instance" "kafka_instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.medium"
  security_groups = [aws_security_group.kafka_sg.name]
  key_name        = "realtime"

  # provisioner "local-exec" {
  #   command = <<EOH
  #       #!/bin/bash
  #       # Install Java
  #       sudo yum update -y
  #       sudo yum install -y java-1.8.0-openjdk-devel
  #       
  #       # Install Kafka
  #       wget https://downloads.apache.org/kafka/3.7.0/kafka_2.12-3.7.0.tgz
  #       tar -xvf kafka_2.12-3.7.0.tgz
  #       cd kafka_2.12-3.7.0

  #       export KAFKA_HEAP_OPTS="-Xmx2G -Xms2G"

  #       # nohup bin/zookeeper-server-start.sh config/zookeeper.properties > zookeeper.log 2>&1 &
  #       

  #       # nohup bin/kafka-server-start.sh config/server.properties > kafka.log 2>&1 &
  #              EOH
  # }

  user_data = <<-EOF
    #!/bin/bash
    # Install Java
    sudo apt update -y
    sudo apt install -y openjdk-8-jdk
    
    # Install Kafka
    wget https://downloads.apache.org/kafka/3.7.0/kafka_2.12-3.7.0.tgz
    tar -xvf kafka_2.12-3.7.0.tgz
    cd kafka_2.12-3.7.0

    export KAFKA_HEAP_OPTS="-Xmx512M -Xms512M"

    #nohup bin/zookeeper-server-start.sh config/zookeeper.properties > zookeeper.log 2>&1 &
    
    bin/zookeeper-server-start.sh -daemon config/zookeeper.properties && \
        bin/kafka-server-start.sh -daemon config/server.properties
  EOF

  tags = {
    Name = "Kafka Instance"
  }
}
