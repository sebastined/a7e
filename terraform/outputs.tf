# AWS Budgets for cost control (only created in production)
resource "aws_budgets_budget" "monthly_cost" {
  count         = var.use_localstack ? 0 : 1
  name          = "${local.prefix}-monthly-budget"
  budget_type   = "COST"
  limit_amount  = "100"
  limit_unit    = "USD"
  time_unit     = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["budget-alerts@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["budget-alerts@example.com"]
  }

  cost_filters = {
    TagKeyValue = "Project$${local.prefix}"
  }
}

# Output important information
output "environment" {
  value = var.env
}

output "region" {
  value = var.region
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "sns_topic_arn" {
  value = module.sns.arn
}

output "kms_key_arn" {
  value = length(module.kms) > 0 ? module.kms[0].key_arn : "KMS disabled for LocalStack"
}
