# DONOTEREADME.MD ✅

**Purpose:** Centralized, human-friendly documentation of the repository changes I made, and step-by-step instructions to run, test, and scan the project locally (LocalStack + Terraform + Lambda unit tests + static scanners).

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
### 1) Start LocalStack (from this repo)
- Using included compose file (example):

  cd terraform
  docker compose up -d

> If you prefer Docker directly: `docker run -d -p 4566:4566 localstack/localstack`

### 2) Quick Terraform validate

  cd terraform
  terraform init -backend=false
  terraform validate

### 3) Plan & Apply (LocalStack)
- Default variables are tuned for local testing. Example plan using LocalStack:

  terraform plan -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566' -var='force_create_on_localstack=false'

- Apply (be attentive: DynamoDB creation on LocalStack may be flaky):

  terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566' -var='force_create_on_localstack=false'

Notes:
- By default this repo avoids creating some resources on LocalStack that are flaky (KMS and DynamoDB). To force creation on LocalStack set `force_create_on_localstack = true`.
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

## Secrets (demo) 🔐
- To create an example SSM SecureString via Terraform:

  terraform apply -var='enable_secrets=true' -var='example_secret_value=supersecret'

- If a KMS key exists (i.e., not using LocalStack), it will be used to encrypt the parameter via `key_id = module.kms[0].key_arn`.

---

## Static scanning & CI 🛡️
- GitHub Actions has a lightweight CI workflow at `.github/workflows/ci.yml` that runs:
  - `terraform validate`
  - `pytest` for Lambda unit tests
  - `tfsec`, `tflint`, and `cfn-nag`

- Snyk: the repository includes instructions for Snyk, but Snyk requires authentication. To run Snyk locally:

  snyk auth
  snyk code test

Or, add SNYK_TOKEN as a GitHub secret and add a Snyk job to the CI workflow if you want automated scanning on PRs.

---

## Notes, caveats & follow-ups ⚠️
- LocalStack DynamoDB creation may be flaky and cause Terraform to wait or time out. For CI stability consider:
  - Using DynamoDB Local in CI, or
  - Running a dedicated integration job on a runner that can create a real ephemeral AWS environment (cost and access permitting).
- The repository includes example/optional features to demonstrate best practices; production usage should be reviewed (e.g., monitoring/alarm thresholds, cross-account KMS policies, least-privilege IAM audits).

---

## Useful commands (cheat-sheet)
- Terraform init/validate: `terraform init -backend=false && terraform validate`
- Terraform plan: `terraform plan -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'`
- Terraform apply: `terraform apply -var='use_localstack=true' -var='localstack_endpoint=http://localhost:4566'`
- Run Lambda unit tests: `pytest -q terraform/lambda/tests`
- Run tfsec locally: `tfsec terraform/` (install via `brew` / `apt` / `apt-get` / official releases)
- Run tflint locally: `tflint` in `terraform/` (install tflint first)
- Run cfn-nag locally: `cfn_nag_scan --input-path cloudformation/`

---

## Contact / Author
- Author: GitHub Copilot (automated changes performed in this repository)

---

If you want, I can:
- Add a Snyk job to GitHub Actions (requires `SNYK_TOKEN` repo secret), or
- Implement a deterministic DynamoDB integration test for CI.

Pick the next step and I will proceed.
