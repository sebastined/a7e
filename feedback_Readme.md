# AWS Engineering Assessment – DevSecOps Test

## Overview

This repository contains the CloudFormation and Terraform configurations for a **secure, serverless S3 file handling architecture** for Accenture. The solution is designed to:

* Track file uploads in DynamoDB.
* Trigger workflows using Lambda and Step Functions.
* Ensure security best practices for S3 and DynamoDB (encryption, versioning, public access blocks).
* Notify a security team via SNS if unencrypted resources are detected.
* Implement lifecycle rules for S3 objects (expire after 90 days).

No actual AWS account is required; LocalStack is used for local testing.

---

## Repository Structure

```
aws-engineering-assessment/
├── cloudformation/
│   └── stack.template         # CloudFormation template for secure S3 buckets
├── terraform/
│   ├── lambda/                # Lambda code (Python)
│   │   └── file_handler.py
│   ├── provider.tf            # Terraform provider configuration
│   ├── main.tf                # All Terraform resources (S3, Lambda, DynamoDB, SNS, Step Functions)
│   ├── terraform.tfstate
│   └── docker-compose.yml     # LocalStack for local testing
├── README.md
└── assignment.drawio.png      # Architecture diagram
```

---

## CloudFormation Template

**File:** `cloudformation/stack.template`

* Creates two S3 buckets:

  * Main bucket: `${BucketName}-s3` (encrypted, versioned, logs to a separate bucket)
  * Logs bucket: `${BucketName}-logs` (encrypted, versioned)
* Includes `Parameters` section with validation for bucket name pattern.
* Outputs the ARNs of both buckets.

**Testing with Kiro:**

```bash
kiro-cli cf validate cloudformation/stack.template
kiro-cli cf audit cloudformation/stack.template --report html
```

> Note: To run full AWS validation, you need valid AWS credentials. For local testing, Kiro performs static analysis.

---

## Terraform Configuration

**Key Resources:**

* **S3 Buckets**: `uploads` and `logs` with:

  * Server-side encryption (AES256)
  * Versioning enabled
  * Public access blocked
  * Lifecycle rules with `filter {}` to comply with Terraform provider
* **Lambda**: `file_handler` with:

  * IAM execution role with least privileges
  * Environment variables pointing to DynamoDB table and SNS topic
  * Dead letter queue (SNS)
  * Reserved concurrent executions
* **DynamoDB**: `Files` table with:

  * Hash key `Filename`, range key `UploadTimestamp`
  * Server-side encryption
  * TTL configured
  * Point-in-time recovery
* **Step Functions**: Workflow with retry and failure handling
* **SNS**: Alert topic and Lambda DLQ

**Local Testing with LocalStack:**

1. Start LocalStack:

```bash
cd terraform
docker-compose up
```

2. Export LocalStack credentials:

```bash
export AWS_ACCESS_KEY_ID=foobar
export AWS_SECRET_ACCESS_KEY=foobar
export AWS_REGION=eu-central-1
```

3. Apply Terraform:

```bash
terraform init
terraform apply
```

4. Test file upload:

```bash
aws --endpoint-url=http://localhost:4566 s3 cp README.md s3://accenture-uploads/
```

5. Check Lambda logs:

```bash
aws --endpoint-url=http://localhost:4566 logs describe-log-groups
aws --endpoint-url=http://localhost:4566 logs describe-log-streams --log-group-name /aws/lambda/file_handler
aws --endpoint-url=http://localhost:4566 logs get-log-events --log-group-name /aws/lambda/file_handler --log-stream-name <stream_name>
```

---

## Notes / Fixes Applied

* Moved **server-side encryption** and **lifecycle rules** into separate Terraform resources.
* Added empty `filter {}` to the lifecycle rule to comply with Terraform provider warnings.
* Lambda and Step Function roles are now least-privilege.
* Terraform configuration validated successfully locally (`terraform validate`) and passed all Kiro checks.

---

## References

* [LocalStack](https://github.com/localstack/localstack)
* [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
* [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

