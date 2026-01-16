aws_region = "us-east-1"

root_account_id = "326698396633"
dev_account_id  = "243581713755"
prod_account_id = "524320491649"

allowed_regions = ["us-east-1", "us-west-2"]

additional_regions = ["us-west-2"]

tags = {
  Project    = "AWS-Organization-Governance"
  CostCenter = "Infrastructure"
  Owner      = "platform-team@example.com"
}

ops_alert_email = "ops-alerts@example.com"
