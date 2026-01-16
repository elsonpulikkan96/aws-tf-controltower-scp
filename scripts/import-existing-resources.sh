#!/bin/bash
set -e

echo "=== Import Existing AWS Resources into Terraform ==="
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI not configured or no valid credentials"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Current AWS Account: $ACCOUNT_ID"
echo ""

cd environments/root

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Import organization
echo ""
echo "Importing AWS Organization..."
ORG_ID=$(aws organizations describe-organization --query 'Organization.Id' --output text 2>/dev/null || echo "")
if [ -n "$ORG_ID" ]; then
    echo "  Organization ID: $ORG_ID"
    # Note: Organization is referenced via data source, not imported
else
    echo "  No organization found or not in management account"
fi

# Import existing accounts (if they exist)
echo ""
echo "To import existing accounts, run:"
echo "  terraform import module.organization.aws_organizations_account.dev 243581713755"
echo "  terraform import module.organization.aws_organizations_account.prod 524320491649"
echo ""
echo "Note: Only run these if the accounts already exist in your organization"
echo ""

echo "=== Import preparation complete ==="
echo ""
echo "Next steps:"
echo "1. Review terraform.tfvars and update email addresses"
echo "2. Run: terraform plan"
echo "3. Review the plan carefully"
echo "4. Run: terraform apply"
