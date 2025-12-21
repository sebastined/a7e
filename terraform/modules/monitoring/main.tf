variable "name" {
  description = "CloudWatch alarm name"
  type        = string
}

variable "metric_name" {
  description = "CloudWatch metric name"
  type        = string
}

variable "namespace" {
  description = "CloudWatch namespace"
  type        = string
}

variable "statistic" {
  description = "CloudWatch statistic"
  type        = string
  default     = "Average"
}

variable "period" {
  description = "CloudWatch period in seconds"
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate"
  type        = number
  default     = 2
}

variable "threshold" {
  description = "Alarm threshold"
  type        = number
}

variable "comparison_operator" {
  description = "Comparison operator"
  type        = string
  default     = "GreaterThanThreshold"
}

variable "alarm_actions" {
  description = "List of alarm actions"
  type        = list(string)
  default     = []
}

variable "dimensions" {
  description = "CloudWatch dimensions"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_actions       = var.alarm_actions
  dimensions          = var.dimensions
  tags                = var.tags
}

output "alarm_arn" {
  value = aws_cloudwatch_metric_alarm.this.arn
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.this.alarm_name
}
