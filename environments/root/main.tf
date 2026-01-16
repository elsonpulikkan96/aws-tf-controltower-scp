terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure after initial setup
    # bucket         = "terraform-state-326698396633"
    # key            = "control-tower/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Repository  = "aws-tf-controltower-scp"
      Environment = "management"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for organization (import existing)
data "aws_organizations_organization" "main" {}

# Organization Module
module "organization" {
  source = "../../modules/organization"
  
  dev_account_id  = var.dev_account_id
  prod_account_id = var.prod_account_id
  root_account_id = var.root_account_id
}

# Control Tower Module
module "control_tower" {
  source = "../../modules/control-tower"
  
  home_region = var.aws_region
  
  depends_on = [module.organization]
}

# Common SCPs
module "scp_common" {
  source = "../../modules/scp"
  
  policy_name        = "common-security-controls"
  policy_description = "Common security controls for all accounts"
  policy_file        = "../../policies/scp/common/security-baseline.json"
  target_ids         = [data.aws_organizations_organization.main.roots[0].id]
}

# Dev Environment SCPs
module "scp_dev" {
  source = "../../modules/scp"
  
  policy_name        = "dev-environment-controls"
  policy_description = "Development environment specific controls"
  policy_file        = "../../policies/scp/dev/dev-controls.json"
  target_ids         = [module.organization.dev_ou_id]
  
  depends_on = [module.organization]
}

# Prod Environment SCPs
module "scp_prod" {
  source = "../../modules/scp"
  
  policy_name        = "prod-environment-controls"
  policy_description = "Production environment specific controls"
  policy_file        = "../../policies/scp/prod/prod-controls.json"
  target_ids         = [module.organization.prod_ou_id]
  
  depends_on = [module.organization]
}

# Tag Policies
module "tag_policy" {
  source = "../../modules/tag-policy"
  
  policy_file = "../../policies/tag-policies/required-tags.json"
  target_ids  = [data.aws_organizations_organization.main.roots[0].id]
}

# Backup Policies
module "backup_policy_dev" {
  source = "../../modules/backup-policy"
  
  environment = "dev"
  policy_file = "../../policies/backup-policies/dev-backup.json"
  target_ids  = [module.organization.dev_ou_id]
  
  depends_on = [module.organization]
}

# Cost Controls Module
module "cost_controls" {
  source = "../../modules/cost-controls"
  
  accounts = {
    management = { account_id = var.root_account_id, limit = "1000" }
    dev        = { account_id = var.dev_account_id, limit = "2000" }
    prod       = { account_id = var.prod_account_id, limit = "5000" }
  }
  
  alert_email = var.ops_alert_email
}

# Operational Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  alert_email = var.ops_alert_email
}

# AWS Config Rules
module "config_rules" {
  source = "../../modules/config-rules"
  
  config_bucket_name = "aws-config-${var.root_account_id}"
}

module "backup_policy_prod" {
  source = "../../modules/backup-policy"
  
  environment = "prod"
  policy_file = "../../policies/backup-policies/prod-backup.json"
  target_ids  = [module.organization.prod_ou_id]
  
  depends_on = [module.organization]
}
