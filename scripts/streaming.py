import boto3
import json
import sys
from pyspark.sql import SparkSession
from time import sleep

# Initialize Spark session
spark = SparkSession.builder \
    .appName("DynamoDBMultiQueryWithTopicsAndSecrets") \
    .getOrCreate()

# Get the S3 checkpoint bucket from the job arguments
if len(sys.argv) < 2:
    print("Usage: spark-submit streaming_job_with_dynamodb_and_secrets.py <checkpoint_bucket> <secret_name>")
    sys.exit(1)

checkpoint_bucket = sys.argv[1]
secret_name = sys.argv[2]  # Secret name passed as a job argument

# Initialize boto3 clients
dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
table = dynamodb.Table('sql_queries')  # Replace with your DynamoDB table name
secrets_client = boto3.client('secretsmanager', region_name='us-west-2')

# Function to retrieve Kafka brokers from Secrets Manager
def get_kafka_brokers_from_secrets(secret_name):
    try:
        get_secret_value_response = secrets_client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response["SecretString"])
        return secret["kafka_brokers"]
    except Exception as e:
        print(f"Failed to retrieve secret: {e}")
        raise e

# Retrieve Kafka broker endpoints
kafka_brokers = get_kafka_brokers_from_secrets(secret_name)

# Function to fetch all queries, input/output topics, view names from DynamoDB
def get_all_queries():
    response = table.scan()
    queries = response['Items']
    query_map = {}
    for query in queries:
        query_map[query['query_id']] = {
            'sql_query': query['sql_query'],
            'input_topic': query['input_topic'],
            'output_topic': query['output_topic'],
            'view_name': query['view_name'],
            'last_updated': query['last_updated']
        }
    return query_map

# Function to start a streaming query for a given SQL query, input/output topics, and view name
def start_streaming_query(query_id, sql_query, input_topic, output_topic, view_name):
    # Read from the input Kafka topic
    df = spark.readStream \
              .format("kafka") \
              .option("subscribe", input_topic) \
              .option("kafka.bootstrap.servers", kafka_brokers) \
              .load()
    
    # Create a temporary view for SQL query execution
    df.createOrReplaceTempView(view_name)
    
    # Run the SQL query
    transformed_df = spark.sql(sql_query)
    
    # Write to the output Kafka topic
    return transformed_df \
        .selectExpr("CAST(value AS STRING)") \
        .writeStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", kafka_brokers) \
        .option("topic", output_topic) \
        .option("checkpointLocation", f"s3://{checkpoint_bucket}/{query_id}/checkpoints/") \
        .start()

# Track running queries and last updated timestamps
running_queries = {}
last_updated_map = {}

# Initialize queries from DynamoDB
queries = get_all_queries()

# Start streaming queries for all initial queries
for query_id, query_data in queries.items():
    sql_query = query_data['sql_query']
    input_topic = query_data['input_topic']
    output_topic = query_data['output_topic']
    view_name = query_data['view_name']
    last_updated = query_data['last_updated']
    
    # Start the streaming query with the respective input/output topics and view name
    running_queries[query_id] = start_streaming_query(query_id, sql_query, input_topic, output_topic, view_name)
    last_updated_map[query_id] = last_updated

# Function to check for changes in queries and restart changed queries
def check_for_query_changes():
    global running_queries
    global last_updated_map
    
    updated_queries = get_all_queries()
    
    for query_id, new_data in updated_queries.items():
        new_sql_query = new_data['sql_query']
        new_input_topic = new_data['input_topic']
        new_output_topic = new_data['output_topic']
        new_view_name = new_data['view_name']
        new_last_updated = new_data['last_updated']
        
        # Check if the query or topics have changed by comparing timestamps
        if new_last_updated != last_updated_map[query_id]:
            print(f"Query {query_id} has changed! Restarting...")
            
            # Stop the old streaming query
            if running_queries[query_id].isActive:
                running_queries[query_id].stop()
            
            # Start the new streaming query with the updated SQL, topics, and view name
            running_queries[query_id] = start_streaming_query(query_id, new_sql_query, new_input_topic, new_output_topic, new_view_name)
            last_updated_map[query_id] = new_last_updated
        else:
            print(f"No changes detected for query {query_id}.")

# Main loop to periodically check for query updates every 10 minutes
while True:
    sleep(20)  # Sleep for 10 minutes
    check_for_query_changes()

