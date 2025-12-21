variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "a7e"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "expiration_days" {
  description = "S3 object expiry (days)"
  type        = number
  default     = 90
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "files"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "use_local_kms" {
  description = "If true, allow fallback when KMS features aren't available in LocalStack"
  type        = bool
  default     = true
}

variable "use_localstack" {
  description = "Run resources against LocalStack endpoints when true"
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "Endpoint URL for LocalStack when use_localstack = true"
  type        = string
  default     = "http://localhost:4566"
}

variable "enable_pytests_in_ci" {
  description = "Enable running python tests in CI (useful to gate changes)."
  type        = bool
  default     = true
}

variable "enable_secrets" {
  description = "Create example secure SSM parameter when true (for demo of secret management)."
  type        = bool
  default     = false
}

variable "example_secret_value" {
  description = "Example secret value for the demo SecureString. Leave empty to skip creating a secret."
  type        = string
  default     = ""
}

variable "example_secret_name" {
  description = "SSM parameter name for the example secret"
  type        = string
  default     = ""
}

variable "force_create_on_localstack" {
  description = "When true, attempt to create certain resources (like DynamoDB) even when using LocalStack"
  type        = bool
  default     = false
}

variable "env" {
  description = "Environment name (used for tags)"
  type        = string
  default     = "development"
}

variable "common_tags" {
  description = "Map of tags to apply to all resources via provider default_tags"
  type        = map(string)
  default = {
    Owner      = "DevOps Team"
    Compliance = "Required"
    Backup     = "Daily"
  }
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "Engineering"
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
}

variable "alert_email" {
  description = "Email address for SNS alerts and alarms"
  type        = string
  default     = ""
}
