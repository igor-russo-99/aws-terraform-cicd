

resource "aws_emrserverless_application" "spark_app" {
  name          = "emr_serverless_sample_application"
  release_label = "emr-6.9.0"
  type          = "spark"

  initial_capacity {
    initial_capacity_type = "Driver"

    initial_capacity_config {
      worker_count = 2
      worker_configuration {
        cpu    = "2 vCPU"
        memory = "4 GB"
      }
    }
  }

  initial_capacity {
    initial_capacity_type = "Executor"

    initial_capacity_config {
      worker_count = 2
      worker_configuration {
        cpu    = "2 vCPU"
        memory = "4 GB"
      }
    }
  }

  maximum_capacity {
    cpu    = "10 vCPU"
    memory = "32 GB"
  }

  tags = {
    Name        = "EMR Serverless"
    Environment = "dev"
  }
}

# Create the IAM role for EMR Serverless Application
resource "aws_iam_role" "emr_serverless_role" {
  name = "EMRServerlessKafkaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "emr-serverless.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "EMR Serverless Role for Kafka"
  }
}




resource "aws_iam_role_policy" "emr_serverless_kafka_policy" {
  role = aws_iam_role.emr_serverless_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          # Kafka permissions for read and write
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:AlterTopic",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          # Allow access to Secrets Manager to retrieve secrets
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })
}




resource "aws_cloudwatch_log_group" "sample_emr_serverless_log_group" {
  name = "sample_emr_job_log_group"
}


resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "igor-sr-your-artifacts-bucket-name"

  tags = {
    Name        = "Artifacts Bucket"
    Environment = "production"
  }
}

# Create the S3 bucket for checkpoints
resource "aws_s3_bucket" "checkpoints_bucket" {
  bucket = "igorsr-your-checkpoints-bucket-name"

  tags = {
    Name        = "Checkpoints Bucket"
    Environment = "production"
  }
}

resource "null_resource" "upload_pyspark_script" {
  provisioner "local-exec" {
    command = <<EOT
      aws s3 cp ./scripts/streaming.py s3://${aws_s3_bucket.artifacts_bucket.bucket}/pyspark_scripts/streaming.py
    EOT
  }

  # Re-upload the script if it changes
  triggers = {
    pyspark_script = sha256(file("./scripts/streaming.py"))
  }

  depends_on = [aws_s3_bucket.artifacts_bucket]
}

resource "null_resource" "stop_spark_job" {
  provisioner "local-exec" {
    command = <<EOT
      JOB_ID=$(aws emr-serverless list-job-runs --region "us-east-1" --application-id ${aws_emrserverless_application.spark_app.id} --query 'jobRuns[?state==`RUNNING`].id' --output text)
      if [ -n "$JOB_ID" ]; then
        echo "Stopping running EMR job: $JOB_ID"
        aws emr-serverless stop-job-run --application-id ${aws_emrserverless_application.spark_app.id} --job-run-id $JOB_ID
      else
        echo "No running jobs found."
      fi
    EOT
  }

  depends_on = [null_resource.upload_pyspark_script]
}

# Submit a new EMR job if the script or configuration changes
resource "null_resource" "submit_spark_job" {
  provisioner "local-exec" {
    command = <<EOT
      aws emr-serverless start-job-run \
        --application-id ${aws_emrserverless_application.spark_app.id} \
        --execution-role-arn ${aws_iam_role.emr_serverless_role.arn} \
        --region "us-east-1" \
        --job-driver '{
          "sparkSubmit": {
            "entryPoint": "s3://${aws_s3_bucket.artifacts_bucket.bucket}/pyspark_scripts/streaming.py",
            "sparkSubmitParameters": "s3://${aws_s3_bucket.checkpoints_bucket.bucket}/checkpoints"
          }
        }' \
        --configuration-overrides '{
          "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
              "logUri": "s3://${aws_s3_bucket.bucket.bucket}/logs/"
            }
          }
        }'
    EOT
  }

  depends_on = [null_resource.stop_spark_job]
}


resource "aws_dynamodb_table" "sql_queries" {
  name         = "sql_queries"
  billing_mode = "PAY_PER_REQUEST" # DynamoDB on-demand mode, you can also use PROVISIONED
  hash_key     = "query_id"        # Primary key for DynamoDB (partition key)

  attribute {
    name = "query_id"
    type = "S" # 'S' stands for String
  }

  tags = {
    Name        = "Streaming Ingestion SQL Queries Table"
    Environment = "dev"
  }
}
resource "aws_dynamodb_table_item" "query_001" {
  table_name = aws_dynamodb_table.sql_queries.name
  hash_key   = "query_id"

  item = <<ITEM
  {
    "query_id": {"S": "query_001"},
    "sql_query": {"S": "SELECT name, age FROM employees WHERE age > 30"},
    "input_topic":  {"S": "input_topic_1"},
    "output_topic":  {"S": "output_topic_1"},
    "view_name":  {"S": "employees"},
    "last_updated": {"S": "2024-09-10T09:00:00Z"}
  }
  ITEM
}

