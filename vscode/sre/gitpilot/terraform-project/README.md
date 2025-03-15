# Terraform Project for AWS Infrastructure

This project sets up a basic AWS infrastructure using Terraform. It includes the creation of a Virtual Private Cloud (VPC), subnets, an internet gateway, route tables, a security group, and an EC2 instance.

## Project Structure

```
terraform-project
├── ssh_keys
│   ├── omega-key          # Private SSH key (keep secure)
│   └── omega-key.pub      # Public SSH key for EC2 access
├── main.tf                # Terraform configuration for AWS resources
├── variables.tf           # Variables for customization
└── README.md              # Project documentation
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- An AWS account with appropriate permissions to create resources.
- AWS CLI configured with your credentials.

## Setup Instructions

1. **Generate SSH Keys**:
   - Navigate to the `ssh_keys` directory.
   - Use the following command to generate a new SSH key pair:
     ```
     ssh-keygen -t rsa -b 4096 -f omega-key -C "your_email@example.com"
     ```
   - This will create two files: `omega-key` (private key) and `omega-key.pub` (public key).

2. **Update Terraform Configuration**:
   - Ensure that the `main.tf` file references the public key located in the `ssh_keys` directory.

3. **Initialize Terraform**:
   - Run the following command in the project root to initialize the Terraform project:
     ```
     terraform init
     ```

4. **Plan the Deployment**:
   - Execute the following command to see what resources will be created:
     ```
     terraform plan
     ```

5. **Apply the Configuration**:
   - Deploy the infrastructure by running:
     ```
     terraform apply
     ```
   - Confirm the action when prompted.

## Security Note

Keep the private SSH key (`omega-key`) secure and do not share it publicly. The public key (`omega-key.pub`) can be shared as needed for access to the EC2 instance.

## Cleanup

To remove all resources created by this project, run:
```
terraform destroy
```

This will delete all AWS resources defined in the Terraform configuration.