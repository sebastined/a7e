import json
import os
import boto3
from datetime import datetime

# Get environment configuration
TABLE_NAME = os.environ.get('TABLE_NAME', 'files')
REGION = os.environ.get('REGION', 'eu-central-1')
SNS_TOPIC = os.environ.get('SNS_TOPIC', '')
AWS_ENDPOINT_URL = os.environ.get('AWS_ENDPOINT_URL', '')

# Initialize AWS clients with error handling
def get_client(service_name):
    """Create AWS client with optional LocalStack endpoint"""
    try:
        kwargs = {'region_name': REGION}
        if AWS_ENDPOINT_URL:
            kwargs['endpoint_url'] = AWS_ENDPOINT_URL
        return boto3.client(service_name, **kwargs)
    except Exception as e:
        print(f"Error creating {service_name} client: {str(e)}")
        raise

dynamodb = get_client('dynamodb')
sns = get_client('sns')

def lambda_handler(event, context):
    """
    Process S3 upload events and store metadata in DynamoDB
    
    Args:
        event: S3 event notification
        context: Lambda context
        
    Returns:
        dict: Response with status code and message
    """
    try:
        # Validate event structure
        if 'Records' not in event:
            raise ValueError("Invalid event structure: missing 'Records' key")
        
        processed_files = []
        
        for record in event['Records']:
            # Extract S3 information with error handling
            try:
                s3_info = record.get('s3', {})
                bucket = s3_info.get('bucket', {}).get('name', '')
                key = s3_info.get('object', {}).get('key', '')
                size = s3_info.get('object', {}).get('size', 0)
                
                if not bucket or not key:
                    print(f"Warning: Skipping record with missing bucket or key")
                    continue
                
                # Store metadata in DynamoDB
                item = {
                    'id': {'S': key},
                    'bucket': {'S': bucket},
                    'size': {'N': str(size)},
                    'timestamp': {'S': datetime.utcnow().isoformat()},
                    'processed': {'BOOL': True}
                }
                
                dynamodb.put_item(
                    TableName=TABLE_NAME,
                    Item=item
                )
                
                processed_files.append({
                    'bucket': bucket,
                    'key': key,
                    'size': size
                })
                
                print(f"Successfully processed: {bucket}/{key}")
                
            except Exception as record_error:
                print(f"Error processing record: {str(record_error)}")
                # Send SNS alert for processing errors
                if SNS_TOPIC:
                    try:
                        sns.publish(
                            TopicArn=SNS_TOPIC,
                            Subject='Lambda Processing Error',
                            Message=f"Error processing S3 record: {str(record_error)}\nRecord: {json.dumps(record)}"
                        )
                        print(f"SNS alert sent for record error")
                    except Exception as sns_error:
                        print(f"Failed to send SNS notification: {str(sns_error)}")
                continue
        
        # Success response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully processed {len(processed_files)} files',
                'files': processed_files
            })
        }
        
        return response
        
    except Exception as e:
        error_msg = f"Lambda execution error: {str(e)}"
        print(error_msg)
        
        # Send critical error alert
        if SNS_TOPIC:
            try:
                sns.publish(
                    TopicArn=SNS_TOPIC,
                    Subject='Critical Lambda Error',
                    Message=error_msg
                )
                print(f"Critical error SNS alert sent")
            except Exception as sns_error:
                print(f"Failed to send critical error notification: {str(sns_error)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }
