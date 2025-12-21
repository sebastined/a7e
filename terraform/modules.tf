data "aws_caller_identity" "current" {}

module "kms" {
  source = "./modules/kms"
  count  = var.use_localstack ? 0 : 1
  alias  = "${local.prefix}-main"
  account_id = data.aws_caller_identity.current.account_id
  create = true
  tags   = merge(var.common_tags, { 
    Name        = "${local.prefix}-kms-key"
    Environment = var.env
    Purpose     = "Data encryption"
  })
}

module "s3" {
  source          = "./modules/s3"
  bucket_name     = "${local.prefix}-files"
  expiration_days = var.expiration_days
  kms_key_arn     = length(module.kms) > 0 ? module.kms[0].key_arn : ""
  tags            = merge(var.common_tags, { 
    Name        = "${local.prefix}-files"
    Environment = var.env
    Purpose     = "File storage"
    DataClass   = "Sensitive"
  })
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  name        = var.dynamodb_table_name
  kms_key_arn = length(module.kms) > 0 ? module.kms[0].key_arn : ""
  enable_pitr = var.use_localstack ? false : true
  # Normally we skip creating the table in LocalStack because of compatibility and long waits.
  # Use force_create_on_localstack to override and try creating the table on LocalStack (for testing).
  create      = var.use_localstack ? (var.force_create_on_localstack ? true : false) : true
  create_timeout = var.use_localstack ? "2m" : "10m"
  force_create_on_localstack = var.force_create_on_localstack
  tags        = merge(var.common_tags, { 
    Name        = "${local.prefix}-files-table"
    Environment = var.env
    Purpose     = "File metadata storage"
    DataClass   = "Sensitive"
  })
}

module "sns" {
  source = "./modules/sns"
  name   = "${local.prefix}-security-alerts"
  kms_key_arn = length(module.kms) > 0 ? module.kms[0].key_arn : ""
  tags   = merge(var.common_tags, { 
    Environment = var.env
    Purpose     = "Security and operational alerts"
  })
}

module "iam" {
  source = "./modules/iam"

  lambda_role_name = "${local.prefix}-lambda-exec"
  sfn_role_name    = "${local.prefix}-sfn-exec"

  # If DynamoDB is not created by Terraform (e.g., LocalStack), fall back to a constructed ARN
  dynamodb_arn = var.use_localstack && !var.force_create_on_localstack ? "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}" : module.dynamodb.table_arn
  s3_bucket_arn = module.s3.bucket_arn
  sns_arn       = module.sns.arn
  region        = var.region
  account_id    = data.aws_caller_identity.current.account_id
  tags = merge(var.common_tags, { 
    Environment = var.env
    Purpose     = "IAM roles and policies"
  })
}

# Create Step Functions policy now that Lambda is in the graph to avoid circular dependency
resource "aws_iam_policy" "sfn_policy" {
  name = "${local.prefix}-sfn-policy"
  tags = merge(var.common_tags, { 
    Environment = var.env
    Purpose     = "Step Functions execution policy"
  })

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["lambda:InvokeFunction"],
        Resource = [module.lambda.function_arn]
      },
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = [module.sns.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_attach" {
  role       = module.iam.sfn_role_arn
  policy_arn = aws_iam_policy.sfn_policy.arn
}

module "lambda" {
  source      = "./modules/lambda"
  name        = "${local.prefix}-file-processor"
  source_dir  = "${path.module}/lambda"
  handler     = var.lambda_handler
  runtime     = var.lambda_runtime
  role_arn    = module.iam.lambda_role_arn
  log_retention = 14
  alarm_actions = [module.sns.arn]
  tracing_mode  = "Active"
  environment = {
    # Use configured table name (works even when DynamoDB is not created by Terraform on LocalStack)
    TABLE_NAME = var.dynamodb_table_name
    REGION     = var.region
    SNS_TOPIC  = module.sns.arn
    AWS_ENDPOINT_URL = var.use_localstack ? var.localstack_endpoint : ""
  }
  use_localstack = var.use_localstack
  force_create_on_localstack = var.force_create_on_localstack
  tags = merge(var.common_tags, { 
    Environment = var.env
    Purpose     = "File processing"
    Runtime     = var.lambda_runtime
  })
  depends_on = [module.iam]
}

# store SNS ARN in parameter store (simple secret/config management)
resource "aws_ssm_parameter" "sns_topic" {
  name  = "/a7e/${local.prefix}/sns_topic_arn"
  type  = "String"
  value = module.sns.arn
}

# Optional example secure parameter to demonstrate secret management (disabled by default)
resource "aws_ssm_parameter" "app_secret" {
  count  = var.enable_secrets && var.example_secret_value != "" ? 1 : 0
  name   = var.example_secret_name != "" ? var.example_secret_name : "/a7e/${var.prefix}/app_secret"
  type   = "SecureString"
  value  = var.example_secret_value
  key_id = length(module.kms) > 0 ? module.kms[0].key_arn : null
  tags   = merge(var.common_tags, { Environment = var.env })
}

output "app_secret_parameter_name" {
  value = length(aws_ssm_parameter.app_secret) > 0 ? aws_ssm_parameter.app_secret[0].name : ""
}

resource "aws_s3_bucket_notification" "s3_to_lambda" {
  bucket = module.s3.bucket_id

  lambda_function {
    lambda_function_arn = module.lambda.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.lambda]
}
