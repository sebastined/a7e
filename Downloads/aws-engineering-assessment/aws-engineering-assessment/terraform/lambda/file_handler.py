import json
import boto3
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
table = dynamodb.Table('Files')

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    try:
        table.put_item(
            Item={
                'Filename': event['Records'][0]['s3']['object']['key'],
                'UploadTimestamp': str(datetime.utcnow())
            }
        )
        logger.info("DynamoDB put_item succeeded")
    except Exception as e:
        logger.error(f"Error writing to DynamoDB: {e}")
        raise e

    return {"statusCode": 200, "body": "Success"}

