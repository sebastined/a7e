variable "name" {
  description = "SSM parameter name"
  type        = string
}

variable "type" {
  description = "SSM parameter type"
  type        = string
  default     = "String"
  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.type)
    error_message = "Type must be String, StringList, or SecureString."
  }
}

variable "value" {
  description = "SSM parameter value"
  type        = string
  sensitive   = true
}

variable "description" {
  description = "SSM parameter description"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID for SecureString parameters"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_ssm_parameter" "this" {
  name        = var.name
  type        = var.type
  value       = var.value
  description = var.description
  key_id      = var.type == "SecureString" ? var.kms_key_id : null
  tags        = var.tags
}

output "parameter_arn" {
  value = aws_ssm_parameter.this.arn
}

output "parameter_name" {
  value = aws_ssm_parameter.this.name
}

output "parameter_version" {
  value = aws_ssm_parameter.this.version
}
