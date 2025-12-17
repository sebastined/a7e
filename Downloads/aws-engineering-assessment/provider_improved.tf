terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "eu-central-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3            = "http://localhost:4566"
    dynamodb      = "http://localhost:4566"
    lambda        = "http://localhost:4566"
    sns           = "http://localhost:4566"
    stepfunctions = "http://localhost:4566"
    iam           = "http://localhost:4566"
    logs          = "http://localhost:4566"
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda Policy with Specific Resources
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.files.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:eu-central-1:*:log-group:/aws/lambda/file_handler:*"
      },
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# Step Functions Execution Role
resource "aws_iam_role" "sfn_exec" {
  name = "sfn_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "sfn_policy"
  role = aws_iam_role.sfn_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.file_handler.arn
      },
      {
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# S3 Bucket with Enhanced Security
resource "aws_s3_bucket" "uploads" {
  bucket = "accenture-uploads"
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "archive-old-files"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_logging" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket" "logs" {
  bucket = "accenture-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Event Notification
resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# DynamoDB with Enhanced Features
resource "aws_dynamodb_table" "files" {
  name         = "Files"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Filename"
  range_key    = "UploadTimestamp"

  attribute {
    name = "Filename"
    type = "S"
  }

  attribute {
    name = "UploadTimestamp"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }
}

resource "aws_sns_topic" "alerts" {
  name = "security-alerts"
}

resource "aws_sns_topic" "dlq" {
  name = "lambda-dlq"
}

# Lambda Function with Enhanced Configuration
resource "aws_lambda_function" "file_handler" {
  filename         = "lambda/file_handler.zip"
  function_name    = "file_handler"
  handler          = "file_handler.handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("lambda/file_handler.zip")
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.files.name
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }

  dead_letter_config {
    target_arn = aws_sns_topic.dlq.arn
  }

  reserved_concurrent_executions = 10
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

# Step Functions with Retry Logic
resource "aws_sfn_state_machine" "workflow" {
  name     = "FileUploadWorkflow"
  role_arn = aws_iam_role.sfn_exec.arn

  definition = jsonencode({
    Comment = "Serverless workflow for file uploads"
    StartAt = "ProcessFile"
    States = {
      ProcessFile = {
        Type     = "Task"
        Resource = aws_lambda_function.file_handler.arn
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed", "Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "NotifyFailure"
          }
        ]
        End = true
      }
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Message  = "File processing workflow failed"
          Subject  = "Step Functions Failure Alert"
        }
        Next = "Failure"
      }
      Failure = {
        Type  = "Fail"
        Cause = "File processing failed after retries"
      }
    }
  })
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.uploads.arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.files.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.file_handler.arn
}

output "step_function_arn" {
  value = aws_sfn_state_machine.workflow.arn
}
