terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Production provider configuration
provider "aws" {
  region = var.region

  # Only use endpoint override for LocalStack
  endpoints {
    s3            = var.use_localstack ? var.localstack_endpoint : null
    dynamodb      = var.use_localstack ? var.localstack_endpoint : null
    lambda        = var.use_localstack ? var.localstack_endpoint : null
    sns           = var.use_localstack ? var.localstack_endpoint : null
    sqs           = var.use_localstack ? var.localstack_endpoint : null
    iam           = var.use_localstack ? var.localstack_endpoint : null
    sts           = var.use_localstack ? var.localstack_endpoint : null
    cloudwatch    = var.use_localstack ? var.localstack_endpoint : null
    logs          = var.use_localstack ? var.localstack_endpoint : null
    kms           = var.use_localstack ? var.localstack_endpoint : null
    ssm           = var.use_localstack ? var.localstack_endpoint : null
    stepfunctions = var.use_localstack ? var.localstack_endpoint : null
  }

  # Disable credential validation for LocalStack
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  
  # Required for LocalStack S3 compatibility
  s3_use_path_style = var.use_localstack

  # Default tags applied to all resources
  default_tags {
    tags = merge(
      var.common_tags,
      {
        ManagedBy   = "Terraform"
        Project     = var.prefix
        Environment = var.env
        CostCenter  = var.cost_center
      }
    )
  }
}

locals {
  prefix = var.prefix
}
