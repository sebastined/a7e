# Technical Assignments

The goal of this assignment is to evaluate your ability to work with Terraform and AWS services. We expect that a developer with some experience should be able to solve this within one to two hours.

Please commit your results to GitHub and send us the URL to your repository, so we can review your work before the interview.

There are two assignments, one with focus on Terraform and one with focus on CloudFormation. So, we expect you to check in Terraform and CloudFormation template files. If you use additional helper frameworks to create the output files, please also check in the code you've written for these frameworks as well.

You'll find the two parts in the folders:
- **terraform** - Terraform infrastructure with AWS Lambda, S3, DynamoDB
- **cloudformation** - CloudFormation stack with security features

**Use LocalStack for local testing** (see deployment section below).

---

## 📋 Table of Contents

- [Improvements](#improvements)
- [Prerequisites](#prerequisites)
- [How to Deploy](#how-to-deploy)
- [How to Test](#how-to-test)
- [CloudFormation Assignment](#cloudformation-assignment)
- [Project Structure](#project-structure)
- [Additional Notes](#additional-notes)
- [TL;DR](#tldr)

---

## ✨ Improvements

The following 6 security and infrastructure improvements have been implemented:

### 1. ✅ No Wildcard IAM Permissions
- All IAM policies use specific actions (no `Action = "*"`)
- CloudWatch Logs scoped to Lambda log groups only
- KMS permissions limited to specific services
- S3 permissions scoped to specific bucket ARN

**Verification:**
```bash
grep -r 'Action.*\*' terraform/modules/iam/main.tf  # Should return nothing
```

### 2. ✅ LocalStack/Production Separation
- Created `terraform/providers.tf` with conditional endpoints
- Environment-specific configuration files (localstack.tfvars, development.tfvars, production.tfvars)
- `use_localstack` variable controls all AWS service endpoints
- Zero hardcoded endpoints in production paths

### 3. ✅ Proper Terraform Module Structure
Created 9 production-ready modules:
- `modules/kms/` - KMS encryption keys with rotation
- `modules/s3/` - S3 bucket with versioning, encryption, lifecycle
- `modules/dynamodb/` - DynamoDB table with PITR and encryption
- `modules/sns/` - SNS topics with KMS encryption
- `modules/lambda/` - Lambda with DLQ, alarms, X-Ray tracing
- `modules/iam/` - Least-privilege IAM roles and policies
- `modules/budget/` - AWS Budgets for cost control
- `modules/monitoring/` - Reusable CloudWatch alarms
- `modules/secrets/` - SSM Parameter Store management

### 4. ✅ Error Handling & Monitoring
- Try-catch blocks with per-record error isolation
- Dead Letter Queue (SQS) for failed invocations
- 3 CloudWatch Alarms (errors > 5/5min, throttles > 10/5min, duration > 80% timeout)
- X-Ray distributed tracing
- Structured error logging with SNS notifications

### 5. ✅ Proper Secret Management
- SSM Parameter Store with SecureString type
- KMS encryption for all secrets
- Customer-managed keys with automatic rotation
- Runtime secret retrieval (not deployment-time)
- No secrets in environment variables

### 6. ✅ Resource Tagging & Cost Controls
- Provider default tags (ManagedBy, Project, Environment, CostCenter)
- Resource-specific tags (Name, Purpose, DataClass, etc.)
- AWS Budgets: $100/month with 80% alert
- S3 lifecycle: 90-day expiration
- CloudWatch log retention: 14 days
- DynamoDB: PAY_PER_REQUEST billing

---

## 🔧 Prerequisites

### Required Software & Minimum Versions

| Tool | Minimum Version | Check Command |
|------|----------------|---------------|
| Docker | 20.10+ | `docker --version` |
| Docker Compose | 1.29+ | `docker-compose --version` |
| Terraform | 1.5.0+ | `terraform --version` |
| AWS CLI | 2.0+ | `aws --version` |
| Python | 3.9+ | `python3 --version` |
| Git | 2.0+ | `git --version` |

<details>
<summary><b>📦 How to Install Prerequisites (Ubuntu/Debian)</b></summary>

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker & Docker Compose
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker  # Refresh group membership

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Python 3.9+ and pip
sudo apt-get install -y python3 python3-pip python3-venv
python3 --version

# Install Git
sudo apt-get install -y git
git --version
```

</details>

<details>
<summary><b>🍎 How to Install Prerequisites (macOS)</b></summary>

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install terraform awscli python@3.9 git
brew install --cask docker

# Verify installations
terraform --version
aws --version
python3 --version
docker --version
git --version
```

</details>

<details>
<summary><b>🪟 How to Install Prerequisites (Windows WSL2)</b></summary>

```bash
# Install WSL2 first, then follow Ubuntu/Debian instructions above
# Or use chocolatey in PowerShell:
choco install terraform awscli python git docker-desktop
```

</details>

### AWS Credentials Setup

<details>
<summary><b>For LocalStack (Local Testing) - No Real AWS Account Needed</b></summary>

Set dummy credentials:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
```

Make permanent by adding to `~/.bashrc` or `~/.zshrc`:
```bash
echo 'export AWS_ACCESS_KEY_ID=test' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY=test' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION=eu-central-1' >> ~/.bashrc
source ~/.bashrc
```

</details>

<details>
<summary><b>For Production AWS Deployment</b></summary>

Configure real AWS credentials:

```bash
aws configure
# Enter your:
# - AWS Access Key ID: [your-access-key-id]
# - AWS Secret Access Key: [your-secret-access-key]
# - Default region name: eu-central-1
# - Default output format: json
```

Verify configuration:
```bash
aws sts get-caller-identity
```

</details>

---

## 🚀 How to Deploy

### Baby Steps Deployment Guide

#### Step 1: Clone the Repository
```bash
git clone https://github.com/sebastined/a7e.git
cd a7e
```

#### Step 2: Start LocalStack
```bash
# Navigate to cloudformation folder
cd cloudformation

# Start LocalStack container
docker-compose up -d

# Wait for LocalStack to be ready (watch for "Ready" message)
docker-compose logs -f localstack
# Press Ctrl+C when you see "Ready."

# Go back to project root
cd ..
```

<details>
<summary><b>🔧 Troubleshooting LocalStack</b></summary>

```bash
# If port 4566 is already in use:
sudo lsof -i :4566
sudo kill -9 <PID>

# If container won't start:
docker-compose down
docker-compose up -d

# Check container status:
docker ps | grep localstack

# View logs:
docker-compose logs localstack
```

</details>

#### Step 3: Initialize Terraform
```bash
# Navigate to terraform folder
cd terraform

# Initialize Terraform (downloads providers and modules)
terraform init
```

**Expected output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

#### Step 4: Validate Configuration
```bash
# Check for syntax errors
terraform validate

# Preview what will be created
terraform plan -var-file="environments/localstack.tfvars"
```

#### Step 5: Deploy Infrastructure
```bash
# Apply the configuration
terraform apply -var-file="environments/localstack.tfvars" -auto-approve
```

**Expected output:**
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:
bucket_name = "a7e-files"
dynamodb_table_name = "files"
lambda_function_name = "a7e-file-processor"
```

<details>
<summary><b>📦 What Gets Created?</b></summary>

- **S3 Bucket**: `a7e-files` (for file storage)
- **DynamoDB Table**: `files` (for metadata)
- **Lambda Function**: `a7e-file-processor` (for processing)
- **SQS Queue**: `a7e-file-processor-dlq` (dead letter queue)
- **SNS Topic**: `a7e-alerts` (for notifications)
- **CloudWatch Log Group**: `/aws/lambda/a7e-file-processor`
- **CloudWatch Alarms**: 3 alarms (errors, throttles, duration)
- **IAM Roles & Policies**: Least-privilege access

</details>

#### Step 6: Verify Deployment
```bash
# Check S3 bucket
aws --endpoint-url=http://localhost:4566 s3 ls

# Check Lambda function
aws --endpoint-url=http://localhost:4566 lambda list-functions

# Check DynamoDB table
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# View Terraform outputs
terraform output
```

---

## 🧪 How to Test

### Baby Steps Testing Guide

#### Step 1: Set Up Python Environment
```bash
# Navigate to lambda folder (from terraform directory)
cd lambda

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # Linux/macOS
# OR
.venv\Scripts\activate     # Windows
```

#### Step 2: Install Dependencies
```bash
# Install Lambda dependencies
pip install -r requirements.txt

# Install testing dependencies
pip install pytest moto boto3 responses
```

#### Step 3: Run Unit Tests
```bash
# Run all tests with verbose output
pytest tests/ -v

# Run with coverage report (optional)
pytest tests/ -v --cov=handler --cov-report=term-missing
```

**Expected output:**
```
tests/test_handler.py::test_successful_processing PASSED     [ 25%]
tests/test_handler.py::test_invalid_event_structure PASSED   [ 50%]
tests/test_handler.py::test_dynamodb_error_handling PASSED   [ 75%]
tests/test_handler.py::test_no_sns_topic PASSED              [100%]

======================== 4 passed in 0.16s ========================
```

#### Step 4: Integration Testing with LocalStack

<details>
<summary><b>Test 1: Upload File to S3</b></summary>

```bash
# Create a test file
echo "Hello from test file!" > /tmp/test.txt

# Upload to S3
aws --endpoint-url=http://localhost:4566 s3 cp /tmp/test.txt s3://a7e-files/

# Verify upload
aws --endpoint-url=http://localhost:4566 s3 ls s3://a7e-files/
```

</details>

<details>
<summary><b>Test 2: Invoke Lambda Function</b></summary>

```bash
# Create Lambda event payload
cat > /tmp/event.json << 'EOF'
{
  "Records": [{
    "s3": {
      "bucket": {"name": "a7e-files"},
      "object": {"key": "test.txt", "size": 1024}
    }
  }]
}
EOF

# Invoke Lambda function
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name a7e-file-processor \
  --payload file:///tmp/event.json \
  /tmp/response.json

# View response
cat /tmp/response.json
```

</details>

<details>
<summary><b>Test 3: Verify DynamoDB Entry</b></summary>

```bash
# Scan DynamoDB table
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name files

# Query specific item
aws --endpoint-url=http://localhost:4566 dynamodb get-item \
  --table-name files \
  --key '{"file_id": {"S": "test.txt"}}'
```

</details>

<details>
<summary><b>Test 4: Check CloudWatch Logs</b></summary>

```bash
# List log streams
aws --endpoint-url=http://localhost:4566 logs describe-log-streams \
  --log-group-name /aws/lambda/a7e-file-processor

# View recent logs
aws --endpoint-url=http://localhost:4566 logs tail \
  /aws/lambda/a7e-file-processor --follow
```

</details>

#### Step 5: Compliance Verification

```bash
# Go back to terraform directory
cd ..

# Test 1: No wildcard IAM permissions
echo "Checking for wildcard IAM permissions..."
grep -r 'Action.*\*' modules/iam/main.tf && echo "❌ FAIL: Found wildcards" || echo "✅ PASS: No wildcards"

# Test 2: Verify all modules exist
echo "Checking module count..."
MODULE_COUNT=$(ls -d modules/*/ | wc -l)
[ "$MODULE_COUNT" -ge 6 ] && echo "✅ PASS: $MODULE_COUNT modules found" || echo "❌ FAIL: Only $MODULE_COUNT modules"

# Test 3: Check CloudWatch alarms
echo "Checking CloudWatch alarms..."
ALARM_COUNT=$(grep -c 'resource "aws_cloudwatch_metric_alarm"' modules/lambda/main.tf)
[ "$ALARM_COUNT" -ge 3 ] && echo "✅ PASS: $ALARM_COUNT alarms configured" || echo "❌ FAIL: Only $ALARM_COUNT alarms"

# Test 4: Verify KMS encryption
echo "Checking KMS encryption..."
grep -q 'enable_key_rotation.*true' modules/kms/main.tf && echo "✅ PASS: KMS rotation enabled" || echo "❌ FAIL: No rotation"

# Test 5: Check SSM secrets
echo "Checking secret management..."
grep -q 'aws_ssm_parameter' modules/secrets/main.tf && echo "✅ PASS: SSM secrets configured" || echo "❌ FAIL: No SSM"
```

#### Step 6: Run All Tests (Automated)
```bash
# Go to project root
cd ..

# Run the automated test script
chmod +x TEST_COMMANDS.sh
./TEST_COMMANDS.sh
```

### Cleanup

```bash
# Destroy infrastructure
cd terraform
terraform destroy -var-file="environments/localstack.tfvars" -auto-approve

# Stop LocalStack
cd ../cloudformation
docker-compose down

# Remove volumes (optional)
docker-compose down -v
```

---

## 📝 CloudFormation Assignment

The CloudFormation assignment focuses on adding security features to an existing stack.

### Assignment
The current basic CloudFormation template doesn't contain additional security features/configurations. Please have a look at the cfn-nag report. There are a couple of findings which have to be fixed. Please extend the CloudFormation template accordingly.

### Usage

#### Start LocalStack
```bash
cd cloudformation
docker-compose up
```
Watch the logs for `Execution of "preload_services" took 986.95ms`

#### Authentication
```bash
export AWS_ACCESS_KEY_ID=foobar
export AWS_SECRET_ACCESS_KEY=foobar
export AWS_REGION=eu-central-1
```

#### AWS CLI Examples
```bash
# List S3 buckets
aws --endpoint-url http://localhost:4566 s3api list-buckets

# Create Stack
aws --endpoint-url http://localhost:4566 cloudformation create-stack \
  --stack-name <STACK_NAME> \
  --template-body file://stack.template \
  --parameters ParameterKey=BucketName,ParameterValue=<BUCKET_NAME>
```

#### CFN-NAG Report
```bash
# Show last report
docker logs cfn-nag

# Recreate report
docker-compose restart cfn-nag
```

---

## 📁 Project Structure

```
.
├── README.md                           # This file
├── TEST_COMMANDS.sh                    # Automated test script
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
    ├── README.md                      # Terraform documentation
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
    │   ├── budget/                    # AWS Budgets
    │   ├── dynamodb/                  # DynamoDB table
    │   ├── iam/                       # IAM roles & policies
    │   ├── kms/                       # KMS encryption
    │   ├── lambda/                    # Lambda function
    │   ├── monitoring/                # CloudWatch alarms
    │   ├── s3/                        # S3 bucket
    │   ├── secrets/                   # SSM parameters
    │   └── sns/                       # SNS topics
    └── scripts/                       # Helper scripts
        ├── create_dlq_localstack.sh
        └── create_dynamodb_localstack.sh
```

---

## 📚 Additional Notes

### Quick Developer Guide

**Run unit tests locally:**
```bash
cd terraform/lambda
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

### CI/CD
A lightweight GitHub Actions workflow has been added at `.github/workflows/ci.yml` that runs:
- `terraform validate`
- Python unit tests (pytest + moto)

### Secrets Demo
An optional example SecureString SSM parameter can be created by setting:
- `enable_secrets = true`
- `example_secret_value` (default disabled)

When a KMS key is available, it will be used to encrypt the secret.

### Security Scanning (Snyk)
This repository is set up to be scanned by Snyk. To run Snyk locally:
```bash
snyk auth  # Authenticate with your account/API token
snyk code test  # Run security scan
```

---

## 🎯 TL;DR

**Quick deployment in 2 minutes:**

```bash
# 1. Clone repo
git clone https://github.com/sebastined/a7e.git && cd a7e

# 2. Start LocalStack
cd cloudformation && docker-compose up -d && cd ..

# 3. Deploy infrastructure
cd terraform && terraform init && \
terraform apply -var-file="environments/localstack.tfvars" -auto-approve

# 4. Run tests
cd lambda && python3 -m venv .venv && source .venv/bin/activate && \
pip install -r requirements.txt && pip install pytest moto && pytest tests/ -v

# 5. Verify deployment
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 lambda list-functions
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

**What you get:**
- ✅ 9 Terraform modules (KMS, S3, DynamoDB, Lambda, SNS, IAM, Budget, Monitoring, Secrets)
- ✅ No wildcard IAM permissions (all specific actions)
- ✅ Full error handling (DLQ, 3 CloudWatch alarms, X-Ray tracing)
- ✅ KMS encryption + SSM secret management
- ✅ Cost controls ($100 budget + lifecycle policies)
- ✅ 4 passing unit tests
- ✅ LocalStack/production separation
- ✅ Production-ready infrastructure

**Project completion status:** ✅ **ALL 6 REQUIREMENTS IMPLEMENTED**

**Assignment duration:** 1-2 hours (as specified)

---

**Repository**: [sebastined/a7e](https://github.com/sebastined/a7e)  
**Last Updated**: December 21, 2025

Have fun! 🚀
