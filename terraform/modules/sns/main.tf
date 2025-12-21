variable "name" {
  description = "SNS topic name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_sns_topic" "main" {
  name              = var.name
  kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "cloudwatch_alarms" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = "alerts@example.com" # Should be configured via variable in production
}

output "arn" {
  value = aws_sns_topic.main.arn
}

output "id" {
  value = aws_sns_topic.main.id
}

output "name" {
  value = aws_sns_topic.main.name
}
