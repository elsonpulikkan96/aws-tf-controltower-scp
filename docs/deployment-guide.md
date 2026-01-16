# Deployment Guide

## Prerequisites Checklist

- [ ] AWS Organizations enabled in management account (326698396633)
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.5.0 installed
- [ ] IAM permissions configured (see `iam-permissions.md`)
- [ ] jq installed (for validation scripts)

## Phase 1: Control Tower Setup (Manual)

### Step 1: Enable Control Tower

1. Log into AWS Console with management account (326698396633)
2. Navigate to AWS Control Tower service
3. Click "Set up landing zone"
4. Configure settings:
   - **Home Region**: us-east-1 (or your preferred region)
   - **Region deny settings**: Select regions to deny
   - **Additional regions**: us-west-2
   - **Log Archive email**: aws-log-archive@example.com
   - **Audit email**: aws-audit@example.com

5. Review and click "Set up landing zone"
6. Wait 30-60 minutes for completion

### Step 2: Verify Control Tower Setup

```bash
# Check Control Tower status
aws controltower list-landing-zones --region us-east-1

# Verify S3 buckets were created
aws s3 ls | grep controltower
```

## Phase 2: Terraform Initialization

### Step 1: Update Configuration

```bash
cd /Users/elsonpealias/kiro/aws-tf-controltower-scp
```

Edit `environments/root/terraform.tfvars`:
- Update email addresses for accounts
- Verify account IDs
- Adjust allowed regions if needed

### Step 2: Validate Policies

```bash
./scripts/validate-policies.sh
```

### Step 3: Initialize Terraform

```bash
cd environments/root
terraform init
```

### Step 4: Import Existing Resources

If your accounts already exist in the organization:

```bash
# Import dev account
terraform import module.organization.aws_organizations_account.dev 243581713755

# Import prod account
terraform import module.organization.aws_organizations_account.prod 524320491649
```

### Step 5: Plan and Review

```bash
terraform plan -out=tfplan
```

Review the plan carefully:
- Check which resources will be created
- Verify no unexpected deletions
- Ensure SCPs are correct

### Step 6: Apply Configuration

```bash
terraform apply tfplan
```

## Phase 3: Account Enrollment

### Enroll Dev Account into Control Tower

**Option A: AWS Console**
1. Go to Control Tower → Organization
2. Click "Enroll account"
3. Select Dev account (243581713755)
4. Choose Dev OU
5. Click "Enroll account"

**Option B: AWS CLI**
```bash
aws controltower enroll-account \
  --account-id 243581713755 \
  --organizational-unit-id <dev-ou-id> \
  --region us-east-1
```

### Enroll Prod Account

Repeat the same process for prod account (524320491649)

## Phase 4: Verification

### Verify OUs Created

```bash
aws organizations list-organizational-units-for-parent \
  --parent-id <root-id>
```

### Verify SCPs Applied

```bash
# List all SCPs
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Check SCP attachments
aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY
```

### Verify Tag Policies

```bash
aws organizations list-policies --filter TAG_POLICY
```

### Verify Backup Policies

```bash
aws organizations list-policies --filter BACKUP_POLICY
```

### Test SCP Enforcement

In dev account, try to:
1. Create an expensive instance type (should be denied)
2. Create a resource without required tags (should be denied)
3. Access a denied region (should be denied)

## Phase 5: Ongoing Management

### Making Policy Changes

1. Edit policy JSON files in `policies/` directory
2. Validate changes:
   ```bash
   ./scripts/validate-policies.sh
   ```
3. Plan and apply:
   ```bash
   cd environments/root
   terraform plan
   terraform apply
   ```

### Adding New Accounts

1. Create account in AWS Organizations
2. Add to `terraform.tfvars`
3. Create account resource in `modules/organization/main.tf`
4. Apply changes
5. Enroll in Control Tower

### Updating Control Tower Controls

Control Tower controls are managed through:
- AWS Console → Control Tower → Controls
- AWS Service Catalog

Enable/disable controls as needed for each OU.

## Troubleshooting

### Issue: Terraform can't find organization

**Solution**: Ensure you're running from management account and organization exists:
```bash
aws organizations describe-organization
```

### Issue: SCP denies Terraform operations

**Solution**: Ensure management account is excluded from restrictive SCPs. Add to SCP:
```json
{
  "Condition": {
    "StringNotEquals": {
      "aws:PrincipalAccount": "326698396633"
    }
  }
}
```

### Issue: Account enrollment fails

**Solution**: 
- Verify account email is verified
- Check account is not in another organization
- Ensure Control Tower is fully set up

### Issue: Policy attachment fails

**Solution**:
- Verify OU exists
- Check policy JSON is valid
- Ensure you have organizations:AttachPolicy permission

## Rollback Procedure

If something goes wrong:

1. **Detach problematic SCPs**:
   ```bash
   aws organizations detach-policy --policy-id <policy-id> --target-id <target-id>
   ```

2. **Revert Terraform changes**:
   ```bash
   terraform plan -destroy
   # Review carefully before destroying
   ```

3. **Restore from backup** (if you have state backups)

## Best Practices

1. **Always test in dev first** - Apply SCPs to dev OU before prod
2. **Use version control** - Commit all changes to git
3. **Document changes** - Add comments to policy files
4. **Regular audits** - Review CloudTrail logs monthly
5. **Backup state** - Enable S3 versioning for Terraform state
6. **Use workspaces** - Consider Terraform workspaces for different environments

## Next Steps

After successful deployment:

1. Set up CI/CD pipeline for policy updates
2. Configure AWS Config rules
3. Enable AWS Security Hub
4. Set up CloudWatch alarms for compliance violations
5. Document runbooks for common operations
6. Train team on policy management
