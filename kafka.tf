
# resource "aws_security_group" "sg" {
#   vpc_id = aws_vpc.vpc.id
# }

# resource "aws_kms_key" "kms" {
#   description = "example"
# }

# resource "aws_cloudwatch_log_group" "test" {
#   name = "msk_broker_logs"
# }

resource "aws_s3_bucket" "bucket" {
  bucket = "igorsr-msk-broker-logs-bucket"
}

# # # resource "aws_s3_bucket_acl" "bucket_acl" {
# # #   bucket = aws_s3_bucket.bucket.id
# # # }


# resource "aws_msk_cluster" "poc_cluster" {
#   cluster_name           = "example"
#   kafka_version          = "3.2.0"
#   number_of_broker_nodes = 2

#   broker_node_group_info {
#     instance_type = "kafka.t3.small"
#     client_subnets = [
#       aws_subnet.subnet_az1.id,
#       aws_subnet.subnet_az2.id
#     ]
#     storage_info {
#       ebs_storage_info {
#         volume_size = 50
#       }
#     }
#     security_groups = [aws_security_group.sg.id]
#   }

#   encryption_info {
#     encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
#   }

#   logging_info {
#     broker_logs {
#       cloudwatch_logs {
#         enabled   = true
#         log_group = aws_cloudwatch_log_group.test.name
#       }
#       s3 {
#         enabled = true
#         bucket  = aws_s3_bucket.bucket.id
#         prefix  = "logs/msk-"
#       }
#     }
#   }

#   tags = {
#     environment = "dev"
#   }
# }

# output "zookeeper_connect_string" {
#   value = aws_msk_cluster.poc_cluster.zookeeper_connect_string
# }

# output "bootstrap_brokers_tls" {
#   description = "TLS connection host:port pairs"
#   value       = aws_msk_cluster.poc_cluster.bootstrap_brokers_tls
# }

# resource "aws_secretsmanager_secret" "kafka_brokers" {
#   name        = "kafka-broker-endpoints"
#   description = "Kafka broker endpoints for MSK Cluster"
# }

# resource "aws_secretsmanager_secret_version" "kafka_brokers_value" {
#   secret_id     = aws_secretsmanager_secret.kafka_brokers.id
#   secret_string = jsonencode({
#     kafka_brokers = aws_msk_cluster.poc_cluster.bootstrap_brokers_tls 
#   })
# }

# resource "aws_iam_policy" "kafka_broker_endpoints_policy" {
#   name        = "KafkaBrokerEndpointsAccessPolicy"
#   description = "Allows retrieving the secret kafka-broker-endpoints from AWS Secrets Manager."

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret"
#         ],
#         Resource = aws_secretsmanager_secret.kafka_brokers.arn 
#       }
#     ]
#   })
# }

