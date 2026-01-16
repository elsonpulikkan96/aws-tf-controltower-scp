# Quick Start Guide

## 1. Prerequisites
```bash
# Install required tools
brew install terraform awscli jq

# Verify installations
terraform version  # Should be >= 1.5.0
aws --version
jq --version
```

## 2. Configure AWS Credentials
```bash
# Configure AWS CLI with management account credentials
aws configure --profile management
# Enter Access Key ID, Secret Access Key, Region (us-east-1)

# Test connection
aws sts get-caller-identity --profile management
```

## 3. Enable Control Tower (Manual - One Time)
1. Log into AWS Console (account 326698396633)
2. Go to AWS Control Tower
3. Click "Set up landing zone"
4. Wait 30-60 minutes

## 4. Initialize Terraform
```bash
cd /Users/elsonpealias/kiro/aws-tf-controltower-scp

# Validate all policies
./scripts/validate-policies.sh

# Initialize Terraform
cd environments/root
terraform init
```

## 5. Review and Customize
```bash
# Edit account emails and settings
vim terraform.tfvars

# Review policies
cat ../../policies/scp/common/security-baseline.json
```

## 6. Deploy
```bash
# Plan
terraform plan -out=tfplan

# Review the plan carefully!

# Apply
terraform apply tfplan
```

## 7. Verify
```bash
# Check organization structure
aws organizations list-organizational-units-for-parent --parent-id <root-id>

# Check SCPs
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Check policy attachments
aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY
```

## Common Commands

```bash
# Validate policies
./scripts/validate-policies.sh

# Plan changes
cd environments/root && terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Import existing account
terraform import module.organization.aws_organizations_account.dev 243581713755
```

## Troubleshooting

**Can't find organization?**
```bash
aws organizations describe-organization
```

**Permission denied?**
- Check IAM permissions (see docs/iam-permissions.md)
- Verify you're using management account credentials

**Policy validation fails?**
- Check JSON syntax with: `jq . policies/scp/common/security-baseline.json`

## Next Steps

1. Read full documentation in `docs/`
2. Enroll accounts into Control Tower
3. Test SCPs in dev environment
4. Set up monitoring and alerts
5. Document your specific customizations

## Support

- Documentation: `docs/` directory
- AWS Control Tower: https://docs.aws.amazon.com/controltower/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/
