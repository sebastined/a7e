# LocalStack environment configuration
use_localstack             = true
localstack_endpoint        = "http://localhost:4566"
env                        = "localstack"
force_create_on_localstack = true
enable_secrets             = true
example_secret_value       = "demo-secret-value"

# LocalStack-specific overrides
common_tags = {
  Owner       = "DevOps Team"
  Compliance  = "Required"
  Backup      = "Daily"
  Environment = "LocalStack"
}
