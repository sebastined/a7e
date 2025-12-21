#!/bin/bash
set -e

echo "🚀 Deploying infrastructure to LocalStack..."
echo ""

# Step 1: Create S3 bucket (workaround for Terraform hanging on LocalStack)
echo "📦 Creating S3 bucket..."
aws --endpoint-url=http://localhost:4566 s3 mb s3://a7e-files 2>/dev/null || echo "Bucket already exists"

# Step 2: Apply Terraform (skip S3 bucket creation)
echo "🔧 Applying Terraform configuration..."
export TF_VAR_skip_s3_creation=true
terraform apply -var-file="environments/localstack.tfvars" -auto-approve

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Verify resources:"
echo "  aws --endpoint-url=http://localhost:4566 s3 ls"
echo "  aws --endpoint-url=http://localhost:4566 lambda list-functions"
echo "  aws --endpoint-url=http://localhost:4566 dynamodb list-tables"
