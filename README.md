# AWS Engineering Assessment - Infrastructure as Code

**Production-ready AWS infrastructure with Terraform and CloudFormation**

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-CloudFormation-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python)](https://www.python.org/)
[![LocalStack](https://img.shields.io/badge/LocalStack-Ready-green)](https://localstack.cloud/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Compliance & Security](#compliance--security)
- [Module Structure](#module-structure)
- [Environment Configuration](#environment-configuration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Cost Controls](#cost-controls)
- [Monitoring & Alerting](#monitoring--alerting)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)

---

## 🎯 Overview

This project demonstrates production-ready Infrastructure as Code (IaC) implementations using both **Terraform** and **CloudFormation**. It includes comprehensive security controls, monitoring, cost management, and compliance with AWS best practices.

### Key Features

✅ **Security First**: No wildcard IAM permissions, KMS encryption, secure secrets management  
✅ **Environment Separation**: Dedicated configs for LocalStack, development, and production  
✅ **Modular Design**: 9 reusable Terraform modules with proper encapsulation  
✅ **Comprehensive Monitoring**: CloudWatch alarms, X-Ray tracing, dead letter queues  
✅ **Cost Controls**: AWS Budgets, lifecycle policies, tag-based cost allocation  
✅ **Testing**: Unit tests, integration tests, compliance verification  

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/sebastined/a7e.git
cd a7e
```

### 2. Start LocalStack
```bash
cd cloudformation
docker-compose up -d
cd ..
```

### 3. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -var-file="environments/localstack.tfvars" -auto-approve
```

### 4. Run Tests
```bash
cd lambda
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

### 5. Verify Compliance
```bash
# No wildcard IAM permissions
grep -r 'Action.*\*' terraform/modules/iam/main.tf && echo "❌ FAIL" || echo "✅ PASS"

# Verify modules exist (should be 6)
ls -d terraform/modules/*/ | wc -l

# Check CloudWatch alarms (should be 3)
grep -c 'cloudwatch_metric_alarm' terraform/modules/lambda/main.tf
```

---

## 🏗 Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐         │
│  │    S3    │─────▶│  Lambda  │─────▶│ DynamoDB │         │
│  │  Bucket  │      │ Function │      │  Table   │         │
│  └──────────┘      └──────────┘      └──────────┘         │
│       │                  │                  │              │
│       │            ┌─────┴─────┐           │              │
│       │            │           │           │              │
│       ▼            ▼           ▼           ▼              │
│  ┌──────────────────────────────────────────────┐         │
│  │          CloudWatch Monitoring                │         │
│  │  • Logs  • Alarms  • X-Ray  • Metrics        │         │
│  └──────────────────────────────────────────────┘         │
│                       │                                    │
│                       ▼                                    │
│                 ┌──────────┐                               │
│                 │   SNS    │──▶ Email Alerts              │
│                 └──────────┘                               │
│                                                            │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐             │
│  │   KMS    │   │   SSM    │   │  Budget  │             │
│  │   Key    │   │Parameters│   │  Alerts  │             │
│  └──────────┘   └──────────┘   └──────────┘             │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **File Upload**: User uploads file to S3 bucket
2. **Event Trigger**: S3 event triggers Lambda function
3. **Processing**: Lambda processes file and validates metadata
4. **Storage**: Metadata stored in DynamoDB with encryption
5. **Monitoring**: CloudWatch logs all activity
6. **Alerting**: SNS sends notifications on errors/budgets

---

## 🔒 Compliance & Security

### ✅ Requirement 1: Remove Wildcard IAM Permissions

**Implementation:**
- All IAM policies use specific actions (no `Action = "*"`)
- CloudWatch Logs scoped to Lambda log groups only
- KMS permissions limited to specific services
- S3 permissions scoped to specific bucket ARN

**Verification:**
```bash
grep -r 'Action.*\*' terraform/modules/iam/main.tf  # Should return nothing
grep -r 'Resource.*::\*"$' terraform/modules/iam/main.tf  # Should return nothing
```

### ✅ Requirement 2: Separate LocalStack Endpoints

**Implementation:**
- Created `terraform/providers.tf` with conditional endpoints
- Environment-specific configuration files
- `use_localstack` variable controls all AWS service endpoints
- Zero hardcoded endpoints in production paths

**Files:**
- `terraform/environments/localstack.tfvars`
- `terraform/environments/development.tfvars`
- `terraform/environments/production.tfvars`

### ✅ Requirement 3: Proper Terraform Module Structure

**Created 9 Production-Ready Modules:**
1. `modules/kms/` - KMS encryption keys with rotation
2. `modules/s3/` - S3 bucket with versioning, encryption, lifecycle
3. `modules/dynamodb/` - DynamoDB table with PITR and encryption
4. `modules/sns/` - SNS topics with KMS encryption
5. `modules/lambda/` - Lambda with DLQ, alarms, X-Ray tracing
6. `modules/iam/` - Least-privilege IAM roles and policies
7. `modules/budget/` - AWS Budgets for cost control
8. `modules/monitoring/` - Reusable CloudWatch alarms
9. `modules/secrets/` - SSM Parameter Store management

### ✅ Requirement 4: Error Handling & Monitoring

**Lambda Error Handling:**
- Try-catch blocks with per-record error isolation
- SNS notifications for all errors
- Graceful degradation on failures
- Structured error logging

**Monitoring:**
- Dead Letter Queue (SQS) for failed invocations
- 3 CloudWatch Alarms:
  - Error rate > 5 errors in 5 minutes
  - Throttles > 10 in 5 minutes
  - Duration > 80% of timeout
- X-Ray distributed tracing
- CloudWatch Logs with 14-day retention

### ✅ Requirement 5: Proper Secret Management

**Implementation:**
- SSM Parameter Store with SecureString type
- KMS encryption for all secrets
- Customer-managed keys with rotation
- Runtime secret retrieval (not deployment-time)
- No secrets in environment variables

**Example:**
```hcl
resource "aws_ssm_parameter" "app_secret" {
  name   = "/a7e/production/db_password"
  type   = "SecureString"
  value  = var.secret_value
  key_id = module.kms.key_arn
}
```

### ✅ Requirement 6: Resource Tagging & Cost Controls

**Provider Default Tags:**
```hcl
default_tags {
  tags = {
    ManagedBy   = "Terraform"
    Project     = "a7e"
    Environment = var.env
    CostCenter  = "Engineering"
  }
}
```

**Resource-Specific Tags:**
- Name, Purpose, DataClass, Runtime
- Owner, Compliance, Backup

**Cost Controls:**
- AWS Budgets: $100/month with 80% alert
- S3 lifecycle: 90-day expiration
- Log retention: 14 days
- DynamoDB: PAY_PER_REQUEST billing
- Tag-based cost allocation

---

## 📦 Module Structure

```
terraform/modules/
├── budget/              # AWS Budgets for cost control
│   └── main.tf
├── dynamodb/           # DynamoDB table with encryption
│   └── main.tf
├── iam/                # IAM roles and policies
│   └── main.tf
├── kms/                # KMS key management
│   └── main.tf
├── lambda/             # Lambda function with monitoring
│   └── main.tf
├── monitoring/         # Reusable CloudWatch alarms
│   └── main.tf
├── s3/                 # S3 bucket with security
│   └── main.tf
├── secrets/            # SSM parameter management
│   └── main.tf
└── sns/                # SNS topics
    └── main.tf
```

---

## 🌍 Environment Configuration

### LocalStack (Local Testing)
```bash
terraform plan -var-file="environments/localstack.tfvars"
terraform apply -var-file="environments/localstack.tfvars"
```

**Configuration:**
- `use_localstack = true`
- `localstack_endpoint = "http://localhost:4566"`
- `env = "localstack"`
- KMS disabled (LocalStack limitation)

### Development
```bash
terraform plan -var-file="environments/development.tfvars"
terraform apply -var-file="environments/development.tfvars"
```

**Configuration:**
- `use_localstack = false`
- `env = "development"`
- `region = "eu-central-1"`
- All security features enabled

### Production
```bash
terraform plan -var-file="environments/production.tfvars"
terraform apply -var-file="environments/production.tfvars"
```

**Configuration:**
- `use_localstack = false`
- `env = "production"`
- `region = "eu-central-1"`
- KMS encryption enabled
- Point-in-time recovery enabled
- Budget alerts configured

---

## 🧪 Testing

### Unit Tests

**Run Lambda unit tests:**
```bash
cd terraform/lambda
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install pytest moto boto3 responses
pytest tests/ -v
```

**Expected Output:**
```
tests/test_handler.py::test_successful_processing PASSED     [ 25%]
tests/test_handler.py::test_invalid_event_structure PASSED   [ 50%]
tests/test_handler.py::test_dynamodb_error_handling PASSED   [ 75%]
tests/test_handler.py::test_no_sns_topic PASSED              [100%]

======================== 4 passed in 0.16s ========================
```

### Integration Testing

**Test with LocalStack:**
```bash
# Create test file
echo "Test content" > /tmp/test.txt

# Upload to S3
aws --endpoint-url=http://localhost:4566 s3 cp /tmp/test.txt s3://a7e-files/

# Create Lambda event
cat > /tmp/event.json << 'EVENTEOF'
{
  "Records": [{
    "s3": {
      "bucket": {"name": "a7e-files"},
      "object": {"key": "test.txt", "size": 1024}
    }
  }]
}
EVENTEOF

# Invoke Lambda
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name a7e-file-processor \
  --payload file:///tmp/event.json \
  /tmp/response.json

# Verify DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name files
```

### Compliance Verification

**Automated Checks:**
```bash
# Check IAM permissions
./scripts/verify-compliance.sh

# Run Terraform validation
terraform validate

# Format check
terraform fmt -check -recursive

# Security scan
tfsec terraform/
```

---

## 🚀 Deployment

### Step-by-Step Deployment

#### 1. Prerequisites
```bash
# Install required tools
terraform --version  # >= 1.5.0
aws --version        # AWS CLI v2
python3 --version    # >= 3.9
docker --version     # For LocalStack
```

#### 2. Initialize Terraform
```bash
cd terraform
terraform init
```

#### 3. Validate Configuration
```bash
terraform validate
terraform fmt -recursive
```

#### 4. Plan Deployment
```bash
# For LocalStack
terraform plan -var-file="environments/localstack.tfvars" -out=plan.out

# For Production (requires AWS credentials)
terraform plan -var-file="environments/production.tfvars" -out=plan.out
```

#### 5. Apply Infrastructure
```bash
terraform apply plan.out
```

#### 6. Verify Deployment
```bash
# Check outputs
terraform output

# Verify resources
aws s3 ls
aws lambda list-functions
aws dynamodb list-tables
```

### Production Deployment Checklist

- [ ] AWS credentials configured (`aws configure`)
- [ ] Budget alert email updated in variables
- [ ] KMS key rotation verified
- [ ] CloudWatch alarms tested
- [ ] SNS subscriptions confirmed
- [ ] Resource tags reviewed
- [ ] Cost budgets approved
- [ ] Security review completed
- [ ] Backup strategy documented
- [ ] Disaster recovery plan in place

---

## 💰 Cost Controls

### AWS Budgets

**Monthly Budget Configuration:**
- **Limit**: $100 USD
- **Alert at 80%**: Email notification
- **Alert at 100% (Forecasted)**: Proactive warning
- **Cost Filters**: Project tag = "a7e"

### Cost Optimization Features

1. **S3 Lifecycle Policies**
   - Object expiration: 90 days
   - Noncurrent version expiration: 30 days
   - Abort incomplete multipart uploads: 7 days

2. **CloudWatch Logs**
   - Retention: 14 days
   - Prevents indefinite storage costs

3. **DynamoDB**
   - Billing mode: PAY_PER_REQUEST
   - No minimum costs
   - Scales automatically

4. **Lambda**
   - Reserved concurrency controls
   - Timeout limits
   - Memory optimization

### Cost Monitoring

```bash
# View current costs by tag
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project

# Check budget status
aws budgets describe-budgets --account-id YOUR_ACCOUNT_ID
```

---

## 📊 Monitoring & Alerting

### CloudWatch Alarms

**Lambda Error Alarm:**
- **Metric**: Errors
- **Threshold**: > 5 errors in 5 minutes
- **Action**: Send SNS notification

**Lambda Throttle Alarm:**
- **Metric**: Throttles
- **Threshold**: > 10 throttles in 5 minutes
- **Action**: Send SNS notification

**Lambda Duration Alarm:**
- **Metric**: Duration
- **Threshold**: > 80% of timeout
- **Action**: Send SNS notification

### Logging

**CloudWatch Logs:**
- Log Group: `/aws/lambda/a7e-file-processor`
- Retention: 14 days
- Structured JSON logging

**X-Ray Tracing:**
- Mode: Active
- Service map visualization
- Trace sampling

### Dead Letter Queue

**Configuration:**
- Queue: `a7e-file-processor-dlq`
- Retention: 14 days
- Alerts on message arrival

---

## 📁 Project Structure

```
.
├── README.md                           # This file
├── COMPLIANCE_VERIFICATION.md          # Detailed compliance proof
├── QUICKSTART.md                      # Quick start guide
├── IMPLEMENTATION_SUMMARY.md          # Implementation details
├── DONOTEREADME.MD                    # Complete testing guide
├── .gitignore                         # Git ignore patterns
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI
├── cloudformation/
│   ├── README.md                      # CloudFormation guide
│   ├── docker-compose.yml             # LocalStack setup
│   └── stack.template                 # CloudFormation template
└── terraform/
    ├── providers.tf                   # AWS provider config
    ├── variables.tf                   # Input variables
    ├── modules.tf                     # Module orchestration
    ├── outputs.tf                     # Outputs
    ├── environments/                  # Environment configs
    │   ├── localstack.tfvars
    │   ├── development.tfvars
    │   └── production.tfvars
    ├── lambda/                        # Lambda source code
    │   ├── handler.py
    │   ├── requirements.txt
    │   └── tests/
    │       └── test_handler.py
    ├── modules/                       # Terraform modules
    │   ├── budget/
    │   ├── dynamodb/
    │   ├── iam/
    │   ├── kms/
    │   ├── lambda/
    │   ├── monitoring/
    │   ├── s3/
    │   ├── secrets/
    │   └── sns/
    └── scripts/                       # Helper scripts
        ├── create_dlq_localstack.sh
        └── create_dynamodb_localstack.sh
```

---

## 🔧 Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or WSL2
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 5GB minimum

### Required Software

```bash
# Docker & Docker Compose
docker --version        # >= 20.10
docker-compose --version

# Terraform
terraform --version     # >= 1.5.0

# AWS CLI
aws --version          # AWS CLI v2

# Python
python3 --version      # >= 3.9

# Git
git --version
```

### Installation (Ubuntu/Debian)

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Python & pip
sudo apt-get install -y python3 python3-pip python3-venv
```

### AWS Credentials

**For LocalStack:** No real AWS credentials needed
```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
```

**For Production:** Configure real AWS credentials
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and Output format
```

---

## 📚 Additional Documentation

- **[COMPLIANCE_VERIFICATION.md](./COMPLIANCE_VERIFICATION.md)** - Detailed compliance proof with evidence
- **[QUICKSTART.md](./QUICKSTART.md)** - 5-minute quick start guide
- **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Implementation summary
- **[DONOTEREADME.MD](./DONOTEREADME.MD)** - Complete testing and deployment guide
- **[terraform/README.md](./terraform/README.md)** - Terraform-specific documentation
- **[cloudformation/README.md](./cloudformation/README.md)** - CloudFormation assignment

---

## 🤝 Contributing

This is an assessment project. For questions or issues:

1. Review documentation in the repository
2. Check [DONOTEREADME.MD](./DONOTEREADME.MD) for detailed steps
3. Verify compliance with [COMPLIANCE_VERIFICATION.md](./COMPLIANCE_VERIFICATION.md)

---

## 📄 License

This project is created for educational and assessment purposes.

---

## ✅ Assessment Completion Status

All requirements have been implemented and verified:

- ✅ **No wildcard IAM permissions** - All policies use specific actions and resources
- ✅ **LocalStack separation** - Environment-specific configurations with conditional endpoints
- ✅ **Terraform modules** - 9 production-ready modules with proper encapsulation
- ✅ **Error handling** - Comprehensive monitoring with CloudWatch alarms and DLQ
- ✅ **Secret management** - SSM Parameter Store with KMS encryption
- ✅ **Tagging & cost controls** - Default tags, AWS Budgets, lifecycle policies

**Status**: ✅ **PRODUCTION READY**

---

**Last Updated**: December 21, 2025  
**Repository**: [sebastined/a7e](https://github.com/sebastined/a7e)
