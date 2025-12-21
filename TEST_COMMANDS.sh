#!/bin/bash
# AWS Engineering Assessment - Test Commands
# Date: December 21, 2025

set -e

echo "=========================================="
echo "AWS INFRASTRUCTURE TESTING COMMANDS"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 1. VERIFY COMPLIANCE ===${NC}"
echo ""
echo "# Check for wildcard IAM permissions"
echo "grep -r 'Action.*\*' terraform/modules/iam/main.tf && echo 'FAIL: Found wildcards' || echo '✅ PASS: No wildcard actions'"
echo ""
echo "grep -r 'Resource.*::\*\"$' terraform/modules/iam/main.tf && echo 'FAIL: Found wildcards' || echo '✅ PASS: No wildcard resources'"
echo ""

echo "# Verify LocalStack separation"
echo "grep 'use_localstack' terraform/providers.tf | wc -l"
echo ""

echo "# Count modules"
echo "ls -d terraform/modules/*/ | wc -l  # Should be 6"
echo ""

echo "# Check monitoring resources"
echo "grep -c 'cloudwatch_metric_alarm' terraform/modules/lambda/main.tf  # Should be 3"
echo ""

echo "# Verify secret management"
echo "grep 'SecureString' terraform/modules.tf"
echo ""

echo "# Check tagging"
echo "grep -c 'common_tags' terraform/modules.tf  # Should be > 5"
echo ""

echo -e "${BLUE}=== 2. START LOCALSTACK ===${NC}"
echo ""
echo "# Start LocalStack with Docker Compose"
echo "cd cloudformation"
echo "docker-compose up -d"
echo "docker-compose ps"
echo "cd .."
echo ""
echo "# Wait for LocalStack to be ready"
echo "sleep 10"
echo ""
echo "# Verify LocalStack is running"
echo "curl -s http://localhost:4566/_localstack/health | python3 -m json.tool"
echo ""

echo -e "${BLUE}=== 3. TERRAFORM DEPLOYMENT ===${NC}"
echo ""
echo "# Initialize Terraform"
echo "cd terraform"
echo "terraform init"
echo ""

echo "# Validate configuration"
echo "terraform validate"
echo ""

echo "# Format check"
echo "terraform fmt -check -recursive"
echo ""

echo "# Plan with LocalStack"
echo "terraform plan -var='use_localstack=true' -var='force_create_on_localstack=false'"
echo ""

echo "# Apply infrastructure"
echo "terraform apply -auto-approve -var='use_localstack=true' -var='force_create_on_localstack=false'"
echo ""

echo -e "${BLUE}=== 4. VERIFY INFRASTRUCTURE ===${NC}"
echo ""
echo "# List S3 buckets"
echo "aws --endpoint-url=http://localhost:4566 s3 ls"
echo ""

echo "# Check Lambda functions"
echo "aws --endpoint-url=http://localhost:4566 lambda list-functions --query 'Functions[].FunctionName'"
echo ""

echo "# List SNS topics"
echo "aws --endpoint-url=http://localhost:4566 sns list-topics"
echo ""

echo "# List IAM roles"
echo "aws --endpoint-url=http://localhost:4566 iam list-roles --query 'Roles[?contains(RoleName, \`a7e\`)].RoleName'"
echo ""

echo "# Check SSM parameters"
echo "aws --endpoint-url=http://localhost:4566 ssm describe-parameters"
echo ""

echo -e "${BLUE}=== 5. CREATE TEST DATA ===${NC}"
echo ""
echo "# Create S3 bucket manually (if needed)"
echo "BUCKET_NAME=\$(terraform output -raw s3_bucket_name 2>/dev/null || echo 'a7e-files')"
echo "aws --endpoint-url=http://localhost:4566 s3 mb s3://\${BUCKET_NAME} 2>/dev/null || echo 'Bucket exists'"
echo ""

echo "# Create DynamoDB table manually (LocalStack compatibility)"
echo "TABLE_NAME=\$(terraform output -raw dynamodb_table_name 2>/dev/null || echo 'files')"
echo "aws --endpoint-url=http://localhost:4566 dynamodb create-table \\"
echo "  --table-name \${TABLE_NAME} \\"
echo "  --attribute-definitions AttributeName=id,AttributeType=S \\"
echo "  --key-schema AttributeName=id,KeyType=HASH \\"
echo "  --billing-mode PAY_PER_REQUEST 2>/dev/null || echo 'Table exists'"
echo ""

echo "# Upload test file to S3"
echo "echo 'Test file content' > /tmp/test-file.txt"
echo "aws --endpoint-url=http://localhost:4566 s3 cp /tmp/test-file.txt s3://\${BUCKET_NAME}/test-file.txt"
echo ""

echo "# Verify file uploaded"
echo "aws --endpoint-url=http://localhost:4566 s3 ls s3://\${BUCKET_NAME}/"
echo ""

echo -e "${BLUE}=== 6. TEST LAMBDA FUNCTION ===${NC}"
echo ""
echo "# Get Lambda function name"
echo "FUNCTION_NAME=\$(terraform output -raw lambda_function_name 2>/dev/null || echo 'a7e-file-processor')"
echo ""

echo "# Create test event"
echo "cat > /tmp/test-event.json << 'EVENTEOF'"
echo '{'
echo '  "Records": ['
echo '    {'
echo '      "s3": {'
echo '        "bucket": {"name": "a7e-files"},'
echo '        "object": {"key": "test-file.txt", "size": 1024}'
echo '      }'
echo '    }'
echo '  ]'
echo '}'
echo "EVENTEOF"
echo ""

echo "# Invoke Lambda directly"
echo "aws --endpoint-url=http://localhost:4566 lambda invoke \\"
echo "  --function-name \${FUNCTION_NAME} \\"
echo "  --payload file:///tmp/test-event.json \\"
echo "  /tmp/lambda-response.json"
echo ""

echo "# Check Lambda response"
echo "cat /tmp/lambda-response.json | python3 -m json.tool"
echo ""

echo "# Check DynamoDB for processed file"
echo "aws --endpoint-url=http://localhost:4566 dynamodb scan \\"
echo "  --table-name \${TABLE_NAME} \\"
echo "  --query 'Items[0]'"
echo ""

echo -e "${BLUE}=== 7. CHECK LOGS ===${NC}"
echo ""
echo "# List CloudWatch log groups"
echo "aws --endpoint-url=http://localhost:4566 logs describe-log-groups \\"
echo "  --query 'logGroups[?contains(logGroupName, \`lambda\`)].logGroupName'"
echo ""

echo "# Get Lambda logs (if available)"
echo "aws --endpoint-url=http://localhost:4566 logs describe-log-streams \\"
echo "  --log-group-name /aws/lambda/\${FUNCTION_NAME} \\"
echo "  --max-items 5 2>/dev/null || echo 'No logs yet'"
echo ""

echo -e "${BLUE}=== 8. VERIFY IAM POLICIES ===${NC}"
echo ""
echo "# Get Lambda role"
echo "ROLE_NAME=\$(aws --endpoint-url=http://localhost:4566 iam list-roles \\"
echo "  --query 'Roles[?contains(RoleName, \`lambda-exec\`)].RoleName' --output text)"
echo ""

echo "# List attached policies"
echo "aws --endpoint-url=http://localhost:4566 iam list-attached-role-policies \\"
echo "  --role-name \${ROLE_NAME} 2>/dev/null || echo 'Role not found'"
echo ""

echo "# Get inline policies"
echo "aws --endpoint-url=http://localhost:4566 iam list-role-policies \\"
echo "  --role-name \${ROLE_NAME} 2>/dev/null || echo 'Role not found'"
echo ""

echo -e "${BLUE}=== 9. PYTHON TESTS (if available) ===${NC}"
echo ""
echo "# Run pytest if tests exist"
echo "if [ -f 'lambda/tests/test_handler.py' ]; then"
echo "  cd lambda"
echo "  python3 -m pytest tests/ -v"
echo "  cd .."
echo "else"
echo "  echo 'No Python tests found'"
echo "fi"
echo ""

echo -e "${BLUE}=== 10. CLEANUP ===${NC}"
echo ""
echo "# Destroy Terraform infrastructure"
echo "terraform destroy -auto-approve -var='use_localstack=true' -var='force_create_on_localstack=false'"
echo ""

echo "# Stop LocalStack"
echo "cd ../cloudformation"
echo "docker-compose down"
echo ""

echo -e "${GREEN}=========================================="
echo "TESTING COMPLETE"
echo "==========================================${NC}"
