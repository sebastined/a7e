# Technical Assignments

The goal of this assignment is to evaluate your ability to work with Terraform and AWS services. We expect that a developer with some experience should be able to solve this within one to two hours.

Please commit your results to GitHub and send us the URL to your repository, so we can review your work before the interview.

There are two assignments, one with focus on Terraform and one with focus on Cloudformation. So, we expect you to check in Terraform and Cloudformation template files. If you use additional helper frameworks to create the output files, please also check in the code you've written for these frameworks as well.

You'll find the two parts in the folders:
- terraform
- cloudformation

 Use LocalStack for local testing (see `terraform/README.md`).

Important notes (quick developer guide):

- Run unit tests locally:
	- cd terraform
	- python -m venv .venv && source .venv/bin/activate
	- pip install -r lambda/requirements.txt
	- pytest -q lambda/tests

- CI: A lightweight GitHub Actions workflow has been added at `.github/workflows/ci.yml` that runs `terraform validate` and the Python unit tests (pytest + moto).

Secrets (demo):

- An optional example SecureString SSM parameter can be created by setting `enable_secrets = true` and providing `example_secret_value` (default disabled). When a KMS key is available it will be used to encrypt the secret.


Have fun!

