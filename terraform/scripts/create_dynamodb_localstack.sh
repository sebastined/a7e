#!/usr/bin/env bash
set -euo pipefail

# Helper to create a DynamoDB table in LocalStack for local testing
# Usage: ./create_dynamodb_localstack.sh <table-name> [localstack-endpoint]

TABLE_NAME=${1:-files}
LOCALSTACK_ENDPOINT=${2:-http://localhost:4566}

echo "Creating DynamoDB table '$TABLE_NAME' on LocalStack at $LOCALSTACK_ENDPOINT"
aws --endpoint-url "$LOCALSTACK_ENDPOINT" dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=Filename,AttributeType=S \
  --key-schema AttributeName=Filename,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --output json

echo
 echo "Table created. You can verify with:"
 echo "  aws --endpoint-url $LOCALSTACK_ENDPOINT dynamodb describe-table --table-name $TABLE_NAME"
