# Technical Assignments – Terraform & CloudFormation

This repository contains two infrastructure assignments demonstrating secure, production-ready AWS infrastructure using **Terraform** and **CloudFormation**, with **LocalStack** used for local testing.

The work is intentionally scoped to what can be completed within **1–2 hours**, while still reflecting real-world engineering standards.

---

## Repository Layout

```
.
├── terraform/        # Terraform-based infrastructure (Lambda, S3, DynamoDB)
├── cloudformation/   # CloudFormation stack with security hardening
└── README.md         # This document
```

---

## What Was Implemented

### Security & Infrastructure Improvements

1. **Least-Privilege IAM**

   * No wildcard permissions
   * Policies scoped to exact services and resources
   * CloudWatch Logs restricted to Lambda log groups

2. **Environment Separation**

   * LocalStack vs AWS handled via variables
   * No hardcoded endpoints
   * Environment-specific `.tfvars`

3. **Modular Terraform Design**

   * Independent, reusable modules:

     * S3, DynamoDB, Lambda, IAM, KMS, SNS, Budgets, Monitoring, Secrets
   * Clear ownership and responsibility per module

4. **Reliability & Observability**

   * Dead Letter Queue for Lambda
   * CloudWatch alarms (errors, throttles, duration)
   * Structured logging and SNS notifications
   * X-Ray tracing enabled

5. **Secure Secret Management**

   * SSM Parameter Store (`SecureString`)
   * KMS encryption with key rotation
   * Runtime retrieval (no secrets in code or env vars)

6. **Cost & Governance Controls**

   * Default resource tagging
   * AWS Budget with alerting
   * S3 lifecycle rules
   * PAY_PER_REQUEST DynamoDB billing

---

## Prerequisites

| Tool           | Minimum Version |
| -------------- | --------------- |
| Docker         | 20.10+          |
| Docker Compose | 1.29+           |
| Terraform      | 1.5+            |
| AWS CLI        | 2.x             |
| Python         | 3.9+            |

### LocalStack Credentials (Local Only)

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
```

---

## Deployment

### 1. Clone Repository

```bash
git clone https://github.com/sebastined/a7e.git
cd a7e
```

---

### 2. Start LocalStack

```bash
cd cloudformation
docker-compose up -d
cd ..
```

---

### 3. Deploy with Terraform (LocalStack)

#### Windows (PowerShell)

```powershell
cd terraform
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="eu-central-1"
terraform init
terraform apply -var-file=environments/localstack.tfvars -auto-approve
```

#### Linux/macOS

```bash
cd terraform
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
terraform init
terraform apply -var-file=environments/localstack.tfvars -auto-approve
```

**Creates:**

* S3 bucket (`a7e-files`) with versioning and encryption
* DynamoDB table (`files`) with GSI
* Lambda function + DLQ
* SNS topic
* CloudWatch alarms
* IAM roles and policies
* SSM Parameters

**⚠️ LocalStack Limitations:**

Some resources may fail or timeout in LocalStack:
- S3 bucket logging (permission errors)
- S3 lifecycle rules (may timeout after 3min)

If deployment fails, import existing resources and retry:
```bash
terraform import -var-file=environments/localstack.tfvars "module.dynamodb.aws_dynamodb_table.main[0]" "files"
terraform apply -var-file=environments/localstack.tfvars -target="module.lambda" -auto-approve
```

---

### Production Deployment (AWS)

```bash
terraform apply -var-file=environments/production.tfvars
```

---

## Testing

### Unit Tests (Lambda)

```bash
cd terraform/lambda
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

---

### Integration Test (LocalStack)

#### Windows (PowerShell)

```powershell
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="eu-central-1"

# Create test file and upload
"hello world" | Out-File -FilePath test.txt -Encoding utf8
aws --endpoint-url http://localhost:4566 s3 cp test.txt s3://a7e-files/

# Verify DynamoDB entry
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name files
```

#### Linux/macOS

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1

echo "hello world" > test.txt
aws --endpoint-url http://localhost:4566 s3 cp test.txt s3://a7e-files/
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name files
```

---

### Automated Validation

```bash
chmod +x TEST_COMMANDS.sh
./TEST_COMMANDS.sh
```

Checks:

* IAM wildcard usage
* Module presence
* CloudWatch alarms
* KMS rotation
* SSM secrets

---

## Cleanup

### Terraform (LocalStack)

```bash
cd terraform
tflocal destroy -var-file=environments/localstack.tfvars -auto-approve
```

If LocalStack hangs during refresh:

```bash
tflocal destroy -var-file=environments/localstack.tfvars -refresh=false -auto-approve
```

---

### Terraform (Production)

```bash
terraform destroy -var-file=environments/production.tfvars
```

---

### LocalStack

```bash
cd cloudformation
docker-compose down -v
```

---

## CloudFormation Assignment

The CloudFormation task focuses on **security hardening** of an existing stack.

### What Was Done

* Fixed `cfn-nag` findings
* Added encryption, least privilege, and secure defaults
* Verified using automated `cfn-nag` container

### Usage

```bash
cd cloudformation
docker-compose up
```

```bash
aws --endpoint-url http://localhost:4566 cloudformation create-stack \
  --stack-name demo \
  --template-body file://stack.template \
  --parameters ParameterKey=BucketName,ParameterValue=test-bucket
```

---

## Known Limitations (LocalStack Only)

* Terraform may hang during CloudWatch Logs or S3 refresh
* This is a known LocalStack + AWS provider limitation
* Production AWS deployments work without issues

---

## TL;DR

```bash
git clone https://github.com/sebastined/a7e.git
cd a7e
cd cloudformation && docker-compose up -d
cd ../terraform
terraform init
terraform apply -var-file=environments/localstack.tfvars -auto-approve
```
