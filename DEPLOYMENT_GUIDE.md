# Deployment Guide - Step by Step

This guide provides detailed deployment instructions following the README with all fixes applied.

## Prerequisites Check

Before deploying, ensure you have:

```bash
# Check versions
terraform --version      # Should be >= 1.5
docker --version         # Should be >= 20.10
docker-compose --version # Should be >= 1.29
aws --version            # Should be >= 2.x
python3 --version        # Should be >= 3.9
```

## Step 1: Clone and Navigate

```bash
cd a7e
git log --oneline -1  # Verify you have the latest commit
```

Output should show: `Fix deployment issues and add security hardening`

## Step 2: Start LocalStack

```bash
cd cloudformation
docker-compose up -d

# Monitor the startup (watch for "Execution of "preload_services" took ...ms")
docker logs localstack -f
```

Expected output:
```
localstack_1  | Execution of "preload_services" took 986.95ms
```

## Step 3: Set AWS Credentials (LocalStack Only)

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
```

For Windows PowerShell:
```powershell
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "eu-central-1"
```

## Step 4: Verify LocalStack is Running

```bash
aws --endpoint-url http://localhost:4566 s3 ls
```

Should return empty (no buckets yet), not an error.

## Step 5: Deploy Terraform to LocalStack

```bash
cd ../terraform

# Initialize Terraform
terraform init

# Plan deployment (to verify)
terraform plan -var-file=environments/localstack.tfvars

# Apply deployment
terraform apply -var-file=environments/localstack.tfvars -auto-approve
```

Expected resources created:
- S3 bucket: `a7e-files`
- DynamoDB table: `files` (with Filename and Upload Timestamp attributes)
- Lambda function: `a7e-file-processor`
- SNS topic: `a7e-security-alerts`
- IAM roles and policies
- CloudWatch log groups and alarms

## Step 6: Verify Deployment

### Verify S3 Bucket

```bash
aws --endpoint-url http://localhost:4566 s3 ls
# Should show: 2025-12-21 12:00:00 a7e-files

aws --endpoint-url http://localhost:4566 s3api head-bucket --bucket a7e-files
# Should return without error
```

### Verify DynamoDB Table

```bash
aws --endpoint-url http://localhost:4566 dynamodb list-tables
# Should show: a7e-files-table or files

aws --endpoint-url http://localhost:4566 dynamodb describe-table --table-name files
# Check for attributes: id (HASH), upload_timestamp (RANGE), filename (GSI)
```

### Verify Lambda Function

```bash
aws --endpoint-url http://localhost:4566 lambda list-functions
# Should show: a7e-file-processor

aws --endpoint-url http://localhost:4566 lambda get-function-configuration --function-name a7e-file-processor
# Should show environment variables: TABLE_NAME, REGION, SNS_TOPIC, AWS_ENDPOINT_URL
```

### Verify SNS Topic

```bash
aws --endpoint-url http://localhost:4566 sns list-topics
# Should show: a7e-security-alerts
```

## Step 7: Run Lambda Unit Tests

```bash
cd terraform/lambda

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/ -v
```

Expected test results:
```
test_successful_processing PASSED
test_invalid_event_structure PASSED
test_dynamodb_error_handling PASSED
test_no_sns_topic PASSED
```

## Step 8: Integration Test - Upload File

```bash
# Create a test file
echo "Hello World" > /tmp/test.txt

# Upload to S3
aws --endpoint-url http://localhost:4566 s3 cp /tmp/test.txt s3://a7e-files/test-file.txt

# Verify Lambda was triggered (check logs)
aws --endpoint-url http://localhost:4566 logs tail /aws/lambda/a7e-file-processor --follow

# Verify DynamoDB entry
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name files
```

Expected DynamoDB entry:
```json
{
  "Items": [
    {
      "id": { "S": "test-file.txt" },
      "filename": { "S": "test-file.txt" },
      "upload_timestamp": { "S": "2025-12-21T12:00:00.000000" },
      "bucket": { "S": "a7e-files" },
      "size": { "N": "11" },
      "processed": { "BOOL": true }
    }
  ]
}
```

## Step 9: Deploy CloudFormation Stack

```bash
cd ../cloudformation

# Create stack
aws --endpoint-url http://localhost:4566 cloudformation create-stack \
  --stack-name accenture-demo \
  --template-body file://stack.template \
  --parameters ParameterKey=BucketName,ParameterValue=demo-bucket

# Verify stack creation
aws --endpoint-url http://localhost:4566 cloudformation describe-stacks \
  --stack-name accenture-demo

# Check CFN-NAG report (if running)
docker logs cfn-nag
```

Expected stack outputs:
- S3BucketARN
- LogsBucketARN
- KMSKeyArn
- SecurityAlertsTopicArn

## Step 10: Verify CloudFormation Resources

```bash
# List S3 buckets created by CloudFormation
aws --endpoint-url http://localhost:4566 s3 ls
# Should show: demo-bucket-s3, demo-bucket-logs

# Verify KMS encryption
aws --endpoint-url http://localhost:4566 s3api get-bucket-encryption --bucket demo-bucket-s3
# Should show KMS encryption enabled

# Verify lifecycle policies
aws --endpoint-url http://localhost:4566 s3api get-bucket-lifecycle-configuration --bucket demo-bucket-s3
# Should show 90-day expiration rule

# Verify bucket policy (SSL enforcement)
aws --endpoint-url http://localhost:4566 s3api get-bucket-policy --bucket demo-bucket-s3
# Should show Deny for non-HTTPS traffic
```

## Cleanup

### Destroy Terraform Resources

```bash
cd terraform
terraform destroy -var-file=environments/localstack.tfvars -auto-approve
```

### Delete CloudFormation Stack

```bash
cd ../cloudformation
aws --endpoint-url http://localhost:4566 cloudformation delete-stack --stack-name accenture-demo
```

### Stop LocalStack

```bash
docker-compose down -v
```

## Troubleshooting

### LocalStack Hangs

If Terraform hangs during S3 or CloudWatch operations:

```bash
# Refresh state without making API calls
terraform refresh -var-file=environments/localstack.tfvars -refresh=false

# Or destroy without refresh
terraform destroy -var-file=environments/localstack.tfvars -refresh=false -auto-approve
```

### DynamoDB Table Not Found

LocalStack may not create tables immediately. Use the helper script:

```bash
cd scripts
./create_dynamodb_localstack.sh files http://localhost:4566
```

### Lambda Function Not Triggered

Ensure S3 bucket notification is configured:

```bash
aws --endpoint-url http://localhost:4566 s3api get-bucket-notification-configuration --bucket a7e-files
```

Should show Lambda as the destination.

## Security Validations

### Check IAM Policies

```bash
# Verify no wildcard permissions in Lambda role
aws --endpoint-url http://localhost:4566 iam get-role-policy \
  --role-name a7e-lambda-exec \
  --policy-name a7e-lambda-exec-inline
```

Should only have specific actions on specific resources.

### Verify Encryption

```bash
# S3 encryption
aws --endpoint-url http://localhost:4566 s3api get-bucket-encryption --bucket a7e-files

# DynamoDB encryption
aws --endpoint-url http://localhost:4566 dynamodb describe-table --table-name files | grep -A5 SSEDescription

# SNS encryption
aws --endpoint-url http://localhost:4566 sns get-topic-attributes \
  --topic-arn arn:aws:sns:eu-central-1:000000000000:a7e-security-alerts
```

All should show encryption enabled.

## Summary of Deployment

✅ **Terraform Deployment**
- Initializes Terraform with proper provider configuration
- Creates all infrastructure modules
- Configures LocalStack-specific settings
- Applies all security hardening

✅ **CloudFormation Deployment**
- Creates S3 buckets with KMS encryption
- Enforces SSL/TLS via bucket policy
- Sets up lifecycle rules for 90-day expiration
- Creates SNS topic for security alerts

✅ **Testing**
- Unit tests for Lambda function
- Integration test with S3 upload
- Verification of DynamoDB entries
- Security policy validation

✅ **Security**
- KMS encryption enabled
- Least-privilege IAM policies
- SSL/TLS enforcement
- Error handling and logging
- SNS alerts for critical events
