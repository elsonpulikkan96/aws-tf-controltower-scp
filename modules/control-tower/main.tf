# Control Tower must be set up manually first
# This module references Control Tower resources after setup

# Data source to reference Control Tower landing zone
# Note: Control Tower doesn't have full Terraform support yet
# Use AWS CLI or Console for initial setup

# Reference Control Tower S3 buckets (created during setup)
data "aws_s3_bucket" "log_archive" {
  bucket = "aws-controltower-logs-${data.aws_caller_identity.current.account_id}-${var.home_region}"
}

data "aws_s3_bucket" "access_logs" {
  bucket = "aws-controltower-s3-access-logs-${data.aws_caller_identity.current.account_id}-${var.home_region}"
}

data "aws_caller_identity" "current" {}

# Control Tower baseline controls are managed through the console
# or AWS Service Catalog

# Output Control Tower information for reference
output "log_archive_bucket" {
  description = "Control Tower log archive bucket"
  value       = data.aws_s3_bucket.log_archive.id
}

output "access_logs_bucket" {
  description = "Control Tower access logs bucket"
  value       = data.aws_s3_bucket.access_logs.id
}
