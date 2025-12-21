variable "budget_name" {
  description = "Budget name"
  type        = string
}

variable "budget_limit" {
  description = "Budget limit in USD"
  type        = number
}

variable "alert_threshold" {
  description = "Alert threshold percentage"
  type        = number
  default     = 80
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for budget alerts"
  type        = string
}

variable "cost_filters" {
  description = "Cost filters for the budget"
  type        = map(list(string))
  default     = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_budgets_budget" "this" {
  name              = var.budget_name
  budget_type       = "COST"
  limit_amount      = var.budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  cost_filter {
    name   = "TagKey"
    values = ["Project"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = []
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = []
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  tags = var.tags
}

output "budget_arn" {
  value = aws_budgets_budget.this.arn
}

output "budget_name" {
  value = aws_budgets_budget.this.name
}
