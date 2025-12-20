# DONOTEREADME.MD ✅

**Purpose:** Centralized, human-friendly documentation of the repository changes I made, and step-by-step instructions to run, test, and scan the project locally (LocalStack + Terraform + Lambda unit tests + static scanners).

---

## Prerequisites & Fresh Ubuntu Setup 🖥️

### For a fresh Ubuntu OS (from scratch)

Run these commands once to set up your environment:

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker & Docker Compose
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker  # or logout/login to apply group

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version  # verify

# Install Python & pip
sudo apt-get install -y python3 python3-pip python3-venv

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version  # verify

# Install Git
sudo apt-get install -y git
```

### For users with prerequisites already installed

Just verify:

```bash
docker --version  # Docker version 20+ recommended
docker-compose --version
terraform --version  # 1.5.x or later
python3 --version  # 3.9+
aws --version  # AWS CLI v2
```

---

## Summary of work performed 🔧
- Removed wildcard usage in KMS policies and hardened IAM permissions.
- Parameterized LocalStack endpoints (no hardcoded `http://localhost:4566`).
- Improved Lambda code: early validation, retry helper for DynamoDB writes, timestamp normalization.
- Added unit tests (pytest + moto) for the Lambda handler.
- Added an optional SecureString SSM parameter feature (controlled by `enable_secrets` and `example_secret_value`).
- Added a simple Step Functions state machine and a CloudWatch alarm to notify SNS on failures.
- Added tags propagation across modules and small IAM improvements (scoped logs access, conditional DynamoDB permission).
- Added basic CI: `terraform validate`, `pytest`, and static scanning steps (`tfsec`, `tflint`, `cfn-nag`).
- Documented Snyk usage (Snyk requires authentication and is not run automatically without credentials).

---

## Quick prerequisites ✅
- Docker & Docker Compose (for LocalStack) or LocalStack running at an accessible endpoint
- Terraform (tested with 1.5.x)
- Python 3.11+ to run unit tests and to create a venv
- Optional: `snyk` CLI if you want to run Snyk locally

---

## Directory overview ✨
- `terraform/` — Terraform configuration and modules
- `terraform/modules/` — modules for s3, iam, kms, lambda, dynamodb, sns, etc.
- `terraform/lambda/` — Lambda source, tests and `requirements.txt`
- `.github/workflows/ci.yml` — CI: terraform validate, pytest, tfsec, tflint, cfn-nag

---

## Local development & testing (recommended flow) 🧪

### Step-by-step deployment & end-to-end test

This section provides the exact sequence of commands to deploy and validate the entire system locally.

### 1) Clone the repository

```bash
git clone https://github.com/sebastined/a7e.git
cd a7e
```

### 2) Start LocalStack (from repo root)

```bash
cd terraform
docker compose up -d
```

Wait a few seconds for LocalStack to start. Verify:

```bash
docker ps --filter name=localstack --format "table {{.Names}}\t{{.Status}}"
# Should show: localstack  Up X seconds (healthy)
```

### 3) Create the DynamoDB table manually (avoids LocalStack creation flakiness)

```bash
./scripts/create_dynamodb_localstack.sh files http://localhost:4566
```

Expected output: Table `files` created with primary key `Filename`.

### 4) Initialize Terraform

```bash
terraform init -backend=false
terraform validate  # Should pass with only S3 versioning deprecation warning
```

### 5) Apply Terraform (skip flaky LocalStack resources)

```bash
terraform apply \
  -var='use_localstack=true' \
  -var='localstack_endpoint=http://localhost:4566' \
  -var='force_create_on_localstack=false' \
  -lock=false \
  -auto-approve
```

This provisions:
- S3 bucket (`a7e-files`)
- Lambda function (`a7e-file-processor`)
- SNS topic (`a7e-security-alerts`)
- IAM roles & policies
- CloudWatch alarms (skipped on LocalStack for speed)
- Step Functions state machine

Wait for completion (30-60 seconds typical).

### 6) Run Lambda unit tests locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r lambda/requirements.txt
pytest -q lambda/tests
```

Expected: `1 passed` (Lambda handler test with moto mocks).

### 7) Test the end-to-end flow: Upload → Lambda → DynamoDB

From repo root:

```bash
cd /path/to/repo/root

# 7a) Upload a test file to S3 (triggers Lambda via S3 notification)
aws --endpoint-url http://localhost:4566 s3 cp README.md s3://a7e-files/README.md

# 7b) Verify the file is in S3
aws --endpoint-url http://localhost:4566 s3 ls s3://a7e-files/

# 7c) Scan DynamoDB to confirm Lambda processed the upload
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name files
```

Expected DynamoDB output:
```json
{
    "Items": [
        {
            "Filename": {
                "S": "README.md"
            },
            "UploadTimestamp": {
                "S": "2025-12-20T10:45:23Z"
            }
        }
    ],
    "Count": 1
}
```

✅ **Success! The end-to-end flow is working: S3 upload → Lambda trigger → DynamoDB write.**

### 8) Run security scanning

#### Lambda unit tests (already ran in step 6); now run static analysis:

```bash
cd terraform

# Validate Terraform (quick check)
terraform validate

# Run tfsec (if installed locally)
tfsec . 2>/dev/null || echo "tfsec not installed; install via: brew install tfsec or apt install tfsec"

# Run tflint (if installed locally)
tflint 2>/dev/null || echo "tflint not installed"
```

#### Run Snyk code scan (requires authentication):

```bash
snyk auth  # Follow link to authenticate
snyk code test
```

---

## Troubleshooting & tips 🔧

### Common issues during deployment

| Issue | Solution |
|-------|----------|
| `error: state lock` | Run with `-lock=false` for local testing: `terraform apply -lock=false ...` |
| `DynamoDB creation hangs` | Use the helper script to create manually: `./scripts/create_dynamodb_localstack.sh` |
| `SQS DLQ creation hangs` | Use the helper to create & import: `./scripts/create_dlq_localstack.sh` then `terraform import` |
| Lambda not triggered on S3 upload | Verify S3 notifications: `aws --endpoint-url http://localhost:4566 s3api get-bucket-notification-configuration --bucket a7e-files` |
| `TABLE_NAME not set` error in Lambda | Ensure DynamoDB table exists before apply: `./scripts/create_dynamodb_localstack.sh files` |
| LocalStack container unhealthy | Restart: `docker compose down && docker compose up -d && sleep 5` |

### Cleanup & reset

```bash
# Stop LocalStack
cd terraform
docker compose down

# Remove Terraform state (to start fresh)
rm -f terraform.tfstate terraform.tfstate.backup .terraform.tfstate.lock.info

# Remove Lambda build artifacts
rm -rf lambda_build/

# Clean Python venv
rm -rf .venv

# Full reset: remove all local artifacts
git clean -fd  # Warning: removes untracked files
```

---

## Plan & Apply (LocalStack)
- Default variables are tuned for local testing. Example plan using LocalStack:


  terraform plan -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566' -var='force_create_on_localstack=false'

- Apply (be attentive: DynamoDB creation on LocalStack may be flaky):

  terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566' -var='force_create_on_localstack=false'

Notes:
- By default this repo avoids creating some resources on LocalStack that are flaky (KMS and DynamoDB). To force creation on LocalStack set `force_create_on_localstack = true`.
 - By default this repo avoids creating some resources on LocalStack that are flaky (KMS, DynamoDB, SQS DLQs). To force creation on LocalStack set `force_create_on_localstack = true` (may be flaky). Alternatively, the DLQ will not be created when `use_localstack = true` and `force_create_on_localstack = false`.

Importing SQS DLQ (LocalStack helper):

If creating an SQS DLQ via Terraform against LocalStack is slow or hangs, you can create it manually and import it into Terraform state:

1. Create the queue using the helper script:

```bash
cd terraform
./scripts/create_dlq_localstack.sh a7e-file-processor-dlq http://localhost:4566
```

2. Import into Terraform state:

```bash
terraform import 'module.lambda.aws_sqs_queue.dlq[0]' '<queue-url-returned-by-script>'
```

3. Re-run apply (without `force_create_on_localstack=true` unless you want TF to try creating it):

```bash
terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'
```

This avoids Terraform waiting on LocalStack SQS creation and is the recommended local workflow.

Creating a DynamoDB table in LocalStack for uploads:

1. Create the table (the Lambda expects a primary key `Filename`):

```bash
cd terraform
./scripts/create_dynamodb_localstack.sh files http://localhost:4566
```

2. Verify the table exists:

```bash
aws --endpoint-url http://localhost:4566 dynamodb describe-table --table-name files
```

3. Apply Terraform (Lambda will be configured to use `files` as `TABLE_NAME` even when DynamoDB wasn't created by Terraform):

```bash
terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566' -var='force_create_on_localstack=false' -auto-approve
```

4. Upload a test file to trigger the function (example using aws CLI):

```bash
aws --endpoint-url http://localhost:4566 s3 cp ./test-file.txt s3://a7e-files/test-file.txt
```

5. Check the DynamoDB table for the inserted item:

```bash
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name files
```

This flow avoids Terraform creating the table (so it bypasses flaky LocalStack table creation) while ensuring IAM and Lambda will operate correctly using the configured table name.
- KMS resources are not created when `use_localstack = true` (this prevents LocalStack KMS CreateKey failures). Therefore SecureString encryption with a KMS key may not work locally unless you use real AWS or adjust the KMS creation flag.

### 4) Run Lambda unit tests (local)

  cd terraform
  python -m venv .venv
  source .venv/bin/activate
  pip install -r lambda/requirements.txt
  pytest -q lambda/tests

Expect: 1+ tests to pass (current single unit test should pass).

### 5) Inspect outputs
- After apply you can list outputs and see `app_secret_parameter_name` when secrets are enabled:

  terraform output

---

## Optional: Secrets (demo) 🔐

This repo includes an optional SSM Parameter Store + KMS integration for secure secret storage.

To enable:

```bash
terraform apply -var='enable_secrets=true' -var='example_secret_value=supersecret'
```

If a KMS key exists (i.e., not using LocalStack), it will encrypt the parameter. Retrieve it with:

```bash
aws ssm get-parameter --name '/a7e-demo-secret' --with-decryption --region us-east-1
```

---

## CI/CD & Security Scanning 🛡️

### GitHub Actions Workflow

The repository includes `.github/workflows/ci.yml` which runs on every push:
- `terraform validate` — syntax & structure check
- `pytest` — Lambda unit tests (moto mocks)
- `tfsec` — Terraform security static analysis
- `tflint` — Terraform linting & best practices
- `cfn-nag` — CloudFormation security checks

All jobs are integrated and must pass before merge (configurable via branch protection rules).

### Local Snyk scanning (optional)

Snyk requires authentication and is not automated in CI by default. To run locally:

```bash
snyk auth
snyk code scan --project-name=a7e-file-processor  # Code scanning
snyk iac test terraform/                          # IaC scanning
```

To add Snyk to GitHub Actions, create a `SNYK_TOKEN` repository secret and add a job to `.github/workflows/ci.yml`.

---

## Notes, caveats & follow-ups ⚠️

**LocalStack & CI/CD:**
- LocalStack DynamoDB and SQS creation may be flaky. For stable CI, consider:
  - Using DynamoDB Local instead, or
  - Running integration tests against a real ephemeral AWS environment (cost & access permitting)
- The included helper scripts (`create_dynamodb_localstack.sh`, `create_dlq_localstack.sh`) provide manual workarounds

**Production readiness:**
- The repo includes optional/example features (SSM secrets, CloudWatch alarms, Step Functions). Before production:
  - Review monitoring thresholds (DLQ alarms, CloudWatch metrics)
  - Audit IAM least-privilege policies (use `aws accessanalyzer validate-policy`)
  - Enable CloudTrail for Lambda & API Gateway logging
  - Implement cross-account KMS policies if needed
  - Add encryption at rest for S3 bucket and DynamoDB

**Known limitations:**
- KMS resources are skipped when `use_localstack=true` (LocalStack KMS API is limited)
- CloudWatch log groups and alarms are skipped on LocalStack (creation is slow)
- SQS DLQ may hang during creation on LocalStack; use helper script instead

---

## Quick reference (cheat-sheet)

| Task | Command |
|------|---------|
| **Init & validate** | `terraform init -backend=false && terraform validate` |
| **Plan (LocalStack)** | `terraform plan -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'` |
| **Apply (LocalStack)** | `terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'` |
| **Run unit tests** | `pytest -q terraform/lambda/tests` |
| **Run tfsec** | `tfsec terraform/` |
| **Run tflint** | `tflint` (from `terraform/` dir) |
| **Run cfn-nag** | `cfn_nag_scan --input-path cloudformation/` |
| **Snyk code scan** | `snyk code scan --project-name=a7e-file-processor` |
| **Snyk IaC scan** | `snyk iac test terraform/` |
| **View Terraform outputs** | `terraform output` |
| **Destroy stack** | `terraform destroy -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'` |

---

## Summary

This repository demonstrates a **DevSecOps-first IaC implementation** with:
- ✅ Secure AWS resources (Lambda, DynamoDB, S3, SNS, Step Functions)
- ✅ Least-privilege IAM policies (no `Resource="*"`)
- ✅ Static analysis (tfsec, tflint, cfn-nag) in CI
- ✅ Unit tests with moto mocks
- ✅ Automated S3 → Lambda → DynamoDB workflow
- ✅ LocalStack dev environment for zero-cost local testing
- ✅ GitHub Actions CI workflow
- ✅ Comprehensive documentation for fresh Ubuntu OS deployment

**For questions or contributions**, refer to the project structure and follow the deployment guide above.

