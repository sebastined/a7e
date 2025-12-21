# Terraform Infrastructure

This Terraform configuration deploys a secure, monitored file processing system on AWS with proper cost controls and environment separation.

## Architecture

- **S3**: Encrypted file storage with lifecycle policies
- **Lambda**: File processing with comprehensive monitoring
- **DynamoDB**: Metadata storage with encryption at rest
- **SNS**: Notifications for alerts and monitoring
- **KMS**: Encryption key management
- **CloudWatch**: Monitoring and alerting
- **SSM**: Secure parameter storage
- **Budgets**: Cost control and alerts

## Environment Configuration

### LocalStack (Development)
```bash
terraform plan -var-file="environments/localstack.tfvars"
terraform apply -var-file="environments/localstack.tfvars"
```

### Development
```bash
terraform plan -var-file="environments/development.tfvars"
terraform apply -var-file="environments/development.tfvars"
```

### Production
```bash
terraform plan -var-file="environments/production.tfvars"
terraform apply -var-file="environments/production.tfvars"
```

## Security Features

- ✅ No wildcard IAM permissions
- ✅ KMS encryption for all data at rest
- ✅ Secure parameter storage with SSM
- ✅ VPC endpoints for private communication (when applicable)
- ✅ Resource-specific IAM policies

## Monitoring & Alerting

- Lambda error rate monitoring
- Lambda throttle monitoring  
- Lambda duration monitoring
- Budget alerts at 80% threshold
- Dead letter queue for failed processing

## Cost Controls

- Monthly budget with SNS alerts
- Resource tagging for cost allocation
- S3 lifecycle policies for cost optimization
- Lambda reserved concurrency limits

## Module Structure

```
modules/
├── budget/          # Cost control and budget alerts
├── dynamodb/        # DynamoDB table with encryption
├── iam/            # IAM roles and policies
├── kms/            # KMS key management
├── lambda/         # Lambda function with monitoring
├── monitoring/     # Reusable CloudWatch alarms
├── s3/             # S3 bucket with security
├── secrets/        # SSM parameter management
└── sns/            # SNS topic for notifications
```

## Testing

Run unit tests:
```bash
cd lambda
python -m pytest tests/ -v
```

Validate Terraform:
```bash
terraform validate
terraform fmt -check -recursive
```

## Compliance Verification

Check for security compliance:
```bash
# No wildcard IAM permissions
grep -r 'Action.*\*' terraform/modules/iam/
grep -r 'Resource.*::\*' terraform/modules/iam/

# Verify environment separation
ls terraform/environments/

# Check monitoring coverage
grep -c 'cloudwatch_metric_alarm' terraform/modules/lambda/main.tf
```
