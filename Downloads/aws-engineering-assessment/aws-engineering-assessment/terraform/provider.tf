terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "eu-central-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    sns            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    iam            = "http://localhost:4566"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "uploads" {
  bucket = "accenture-uploads"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "expire-old-files"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

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
}

resource "aws_sns_topic" "alerts" {
  name = "security-alerts"
}

resource "aws_lambda_function" "file_handler" {
  filename         = "lambda/file_handler.zip"
  function_name    = "file_handler"
  handler          = "file_handler.handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("lambda/file_handler.zip")
  role             = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

resource "aws_s3_bucket_notification" "uploads_notification" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_sfn_state_machine" "workflow" {
  name     = "FileUploadWorkflow"
  role_arn = aws_iam_role.lambda_exec.arn

  definition = <<EOF
{
  "Comment": "Serverless workflow for file uploads",
  "StartAt": "ProcessFile",
  "States": {
    "ProcessFile": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.file_handler.arn}",
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "Failure"
        }
      ],
      "End": true
    },
    "Failure": {
      "Type": "Fail",
      "Cause": "File processing failed"
    }
  }
}
EOF
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

