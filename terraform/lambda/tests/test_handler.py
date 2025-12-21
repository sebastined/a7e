import json
import pytest
from unittest.mock import patch, MagicMock
import os
import sys

# Add the parent directory to the path so we can import handler
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class TestLambdaHandler:
    
    @patch.dict(os.environ, {
        'TABLE_NAME': 'test-table',
        'REGION': 'us-east-1',
        'SNS_TOPIC': 'arn:aws:sns:us-east-1:123456789012:test-topic',
        'AWS_ENDPOINT_URL': ''
    })
    @patch('handler.dynamodb')
    @patch('handler.sns')
    def test_successful_processing(self, mock_sns, mock_dynamodb):
        """Test successful S3 event processing"""
        # Import after patching
        from handler import lambda_handler
        
        # Mock DynamoDB put_item
        mock_dynamodb.put_item.return_value = {}
        
        # Create test event
        event = {
            'Records': [
                {
                    's3': {
                        'bucket': {'name': 'test-bucket'},
                        'object': {'key': 'test-file.txt', 'size': 1024}
                    }
                }
            ]
        }
        
        # Call handler
        response = lambda_handler(event, {})
        
        # Verify response
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['message'] == 'Successfully processed 1 files'
        assert len(body['files']) == 1
        assert body['files'][0]['bucket'] == 'test-bucket'
        assert body['files'][0]['key'] == 'test-file.txt'
        
        # Verify DynamoDB was called
        mock_dynamodb.put_item.assert_called_once()
        
    @patch.dict(os.environ, {
        'TABLE_NAME': 'test-table',
        'REGION': 'us-east-1',
        'SNS_TOPIC': 'arn:aws:sns:us-east-1:123456789012:test-topic',
        'AWS_ENDPOINT_URL': ''
    })
    @patch('handler.dynamodb')
    @patch('handler.sns')
    def test_invalid_event_structure(self, mock_sns, mock_dynamodb):
        """Test handling of invalid event structure"""
        # Import after patching
        from handler import lambda_handler
        
        # Create invalid event
        event = {'invalid': 'structure'}
        
        # Call handler
        response = lambda_handler(event, {})
        
        # Verify error response
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'Invalid event structure' in body['error']
        
    @patch.dict(os.environ, {
        'TABLE_NAME': 'test-table',
        'REGION': 'us-east-1',
        'SNS_TOPIC': 'arn:aws:sns:us-east-1:123456789012:test-topic',
        'AWS_ENDPOINT_URL': ''
    })
    @patch('handler.dynamodb')
    @patch('handler.sns')
    def test_dynamodb_error_handling(self, mock_sns, mock_dynamodb):
        """Test DynamoDB error handling"""
        # Import after patching
        from handler import lambda_handler
        
        # Mock DynamoDB to raise exception
        mock_dynamodb.put_item.side_effect = Exception("DynamoDB error")
        
        # Create test event
        event = {
            'Records': [
                {
                    's3': {
                        'bucket': {'name': 'test-bucket'},
                        'object': {'key': 'test-file.txt', 'size': 1024}
                    }
                }
            ]
        }
        
        # Call handler
        response = lambda_handler(event, {})
        
        # Should still return success but with 0 processed files
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['message'] == 'Successfully processed 0 files'
        
    @patch.dict(os.environ, {
        'TABLE_NAME': 'test-table',
        'REGION': 'us-east-1',
        'SNS_TOPIC': '',  # No SNS topic
        'AWS_ENDPOINT_URL': ''
    })
    @patch('handler.dynamodb')
    def test_no_sns_topic(self, mock_dynamodb):
        """Test operation without SNS topic configured"""
        # Import after patching
        from handler import lambda_handler
        
        # Mock DynamoDB put_item
        mock_dynamodb.put_item.return_value = {}
        
        # Create test event
        event = {
            'Records': [
                {
                    's3': {
                        'bucket': {'name': 'test-bucket'},
                        'object': {'key': 'test-file.txt', 'size': 1024}
                    }
                }
            ]
        }
        
        # Call handler
        response = lambda_handler(event, {})
        
        # Should still work without SNS
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['message'] == 'Successfully processed 1 files'
