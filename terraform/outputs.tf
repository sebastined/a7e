# Output important information
output "environment" {
  value = var.env
}

output "region" {
  value = var.region
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "sns_topic_arn" {
  value = module.sns.arn
}

output "kms_key_arn" {
  value = length(module.kms) > 0 ? module.kms[0].key_arn : "KMS disabled for LocalStack"
}
