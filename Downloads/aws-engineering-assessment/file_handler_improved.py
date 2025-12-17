import json
import boto3
import os
from datetime import datetime, timedelta

TABLE_NAME = os.getenv("TABLE_NAME", "Files")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

dynamodb = boto3.resource("dynamodb", endpoint_url=os.getenv("DYNAMODB_ENDPOINT"))
sns = boto3.client("sns", endpoint_url=os.getenv("SNS_ENDPOINT"))
s3 = boto3.client("s3", endpoint_url=os.getenv("S3_ENDPOINT"))

def handler(event, context):
    try:
        table = dynamodb.Table(TABLE_NAME)
        
        for record in event.get("Records", []):
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]
            size = record["s3"]["object"].get("size", 0)
            timestamp = datetime.utcnow().isoformat()
            
            # Check encryption
            try:
                response = s3.head_object(Bucket=bucket, Key=key)
                encryption = response.get("ServerSideEncryption", "None")
            except Exception as e:
                encryption = "Unknown"
                print(f"Error checking encryption: {str(e)}")
            
            # Store with TTL (90 days)
            expiration_time = int((datetime.utcnow() + timedelta(days=90)).timestamp())
            
            table.put_item(Item={
                "Filename": key,
                "UploadTimestamp": timestamp,
                "Bucket": bucket,
                "Size": size,
                "Encryption": encryption,
                "ExpirationTime": expiration_time
            })
            
            # Security checks
            if encryption == "None":
                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Message=f"Unencrypted file detected: {key} in bucket {bucket}",
                    Subject="Security Alert - Unencrypted File"
                )
            
            if not bucket.startswith("accenture"):
                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Message=f"Unexpected bucket detected: {bucket}",
                    Subject="Security Alert - Bucket Naming"
                )
        
        return {"statusCode": 200, "body": json.dumps("Processed successfully")}
    
    except Exception as e:
        print(f"Error processing event: {str(e)}")
        raise
