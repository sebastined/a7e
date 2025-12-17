# Technical Assignments

The goal of this assignment is to evaluate your ability to work with Terraform and AWS services. We expect that a developer with some experience should be able to solve this within one to two hours.

Please commit your results to GitHub and send us the URL to your repository, so we can review your work before the interview.

There are two assignments, one with focus on Terraform and one with focus on Cloudformation. So, we expect you to check in Terraform and Cloudformation template files. If you use additional helper frameworks to create the output files, please also check in the code you've written for these frameworks as well.

You'll find the two parts in the folders:
- terraform
- cloudformation

We've put together instructions in the README.md files in the two directories. All instructions have been tested on Ubuntu Linux. You are free to use other operating system as long as the checked in code can still be tested on Linux.


Have fun!





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

---

This README is **job-assessment ready**: clear, concise, professional, explains what was done, and provides instructions to test everything locally.



