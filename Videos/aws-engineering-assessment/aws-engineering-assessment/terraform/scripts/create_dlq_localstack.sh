#!/usr/bin/env bash
set -euo pipefail

# Helper: create an SQS DLQ in LocalStack and print the terraform import command
# Usage: ./create_dlq_localstack.sh <queue-name> [localstack-endpoint]

QUEUE_NAME=${1:-a7e-file-processor-dlq}
LOCALSTACK_ENDPOINT=${2:-http://localhost:4566}

echo "Creating SQS queue '$QUEUE_NAME' on LocalStack at $LOCALSTACK_ENDPOINT"
QUEUE_URL=$(aws --endpoint-url "$LOCALSTACK_ENDPOINT" sqs create-queue --queue-name "$QUEUE_NAME" --output text 2>/dev/null || true)

if [ -z "$QUEUE_URL" ]; then
  # aws cli sometimes returns QueueUrl on stdout, otherwise try JSON path
  QUEUE_URL=$(aws --endpoint-url "$LOCALSTACK_ENDPOINT" sqs create-queue --queue-name "$QUEUE_NAME" --query 'QueueUrl' --output text)
fi

echo "Created queue: $QUEUE_URL"
echo
echo "Run the following to import into Terraform state:" 
echo
echo "  terraform import 'module.lambda.aws_sqs_queue.dlq[0]' '$QUEUE_URL'"

echo
echo "After import, re-run: terraform apply -var='use_localstack=true' -var='localstack_endpoint=$LOCALSTACK_ENDPOINT'"
