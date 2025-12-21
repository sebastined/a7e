# Production environment configuration
use_localstack = false
env            = "production"
enable_secrets = true

# Production-specific settings
expiration_days = 365
lambda_runtime  = "python3.11"

# Production tags
common_tags = {
  Owner       = "DevOps Team"
  Compliance  = "Required"
  Backup      = "Daily"
  Environment = "Production"
  CostCenter  = "Engineering"
  DataClass   = "Sensitive"
}
