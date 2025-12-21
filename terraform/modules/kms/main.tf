variable "alias" {
  description = "KMS key alias name"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "create" {
  description = "Whether to create KMS key"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region for service conditions"
  type        = string
}

resource "aws_kms_key" "main" {
  count               = var.create ? 1 : 0
  description         = "KMS key for ${var.alias}"
  enable_key_rotation = true
  tags                = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "s3.${var.region}.amazonaws.com",
              "dynamodb.${var.region}.amazonaws.com",
              "sns.${var.region}.amazonaws.com",
              "ssm.${var.region}.amazonaws.com",
              "logs.${var.region}.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "Allow services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "dynamodb.amazonaws.com",
            "sns.amazonaws.com",
            "ssm.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "main" {
  count         = var.create ? 1 : 0
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.main[0].key_id
}

output "key_arn" {
  value = var.create ? aws_kms_key.main[0].arn : ""
}

output "key_id" {
  value = var.create ? aws_kms_key.main[0].key_id : ""
}
