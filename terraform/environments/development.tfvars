# Development environment configuration
use_localstack = false
env            = "development"
enable_secrets = false

# Development-specific settings
expiration_days = 30
lambda_runtime  = "python3.11"

# Development tags
common_tags = {
  Owner       = "DevOps Team"
  Compliance  = "Required"
  Backup      = "Weekly"
  Environment = "Development"
  CostCenter  = "Engineering"
}
