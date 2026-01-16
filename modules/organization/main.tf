data "aws_organizations_organization" "main" {}

# Workloads OU
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Dev OU under Workloads
resource "aws_organizations_organizational_unit" "dev" {
  name      = "Dev"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

# Prod OU under Workloads
resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

# Security OU
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Sandbox OU
resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Reference existing accounts
# Note: Accounts already exist, we just need to move them to correct OUs
# Use aws_organizations_account resource to manage OU placement

resource "aws_organizations_account" "dev" {
  name      = "Dev"
  email     = "aws-dev@example.com"  # Update with actual email
  parent_id = aws_organizations_organizational_unit.dev.id
  
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [email, name]  # Don't try to change existing account
  }
}

resource "aws_organizations_account" "prod" {
  name      = "Prod"
  email     = "aws-prod@example.com"  # Update with actual email
  parent_id = aws_organizations_organizational_unit.prod.id
  
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [email, name]  # Don't try to change existing account
  }
}
