variable "name" {
  description = "DynamoDB table name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = ""
}

variable "enable_pitr" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "create" {
  description = "Whether to create the table"
  type        = bool
  default     = true
}

variable "create_timeout" {
  description = "Timeout for table creation"
  type        = string
  default     = "10m"
}

variable "force_create_on_localstack" {
  description = "Force creation on LocalStack (for testing)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_dynamodb_table" "main" {
  count          = var.create ? 1 : 0
  name           = var.name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  tags           = var.tags

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = var.kms_key_arn != "" ? true : false
    kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  timeouts {
    create = var.create_timeout
    update = "10m"
    delete = "10m"
  }
}

output "table_arn" {
  value = var.create ? aws_dynamodb_table.main[0].arn : ""
}

output "table_name" {
  value = var.create ? aws_dynamodb_table.main[0].name : var.name
}

output "table_id" {
  value = var.create ? aws_dynamodb_table.main[0].id : ""
}
