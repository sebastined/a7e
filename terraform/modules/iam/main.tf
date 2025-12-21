variable "lambda_role_name" {
  type = string
}

variable "sfn_role_name" {
  type = string
}

variable "dynamodb_arn" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "lambda_arn" {
  type    = string
  default = ""
}

variable "sns_arn" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_group_arn" {
  type    = string
  default = ""
}

locals {
  dynamodb_statement = var.dynamodb_arn != "" ? [
    {
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
      ]
      Resource = [var.dynamodb_arn]
    }
  ] : []

  s3_statement = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
    }
  ]

  logs_statement = [
    var.log_group_arn != "" ? {
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = var.log_group_arn
      } : {
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"
    }
  ]

  statements = concat(local.dynamodb_statement, local.s3_statement, local.logs_statement)
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_role_name}-inline"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = local.statements
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_cloudwatch" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "sfn_role" {
  name = var.sfn_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}
/*
  Step Functions policy is created at the root level so that it can reference other resources (e.g., Lambda) without creating a circular dependency between modules.
*/

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "sfn_role_arn" {
  value = aws_iam_role.sfn_role.arn
}

output "lambda_role_name" {
  value = aws_iam_role.lambda_exec.name
}
