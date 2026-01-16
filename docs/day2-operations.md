# Day-2 Operations Guide

## Daily Operations

### Morning Checklist (15 minutes)
```bash
# 1. Check budget status
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=LINKED_ACCOUNT

# 2. Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]'

# 3. Check Config compliance
aws configservice describe-compliance-by-config-rule \
  --compliance-types NON_COMPLIANT \
  --query 'ComplianceByConfigRules[*].[ConfigRuleName,Compliance.ComplianceType]'

# 4. Review CloudTrail for anomalies
aws cloudtrail lookup-events \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AccessDenied \
  --max-results 20
```

---

## Adding a New Account

### Step 1: Create Account
```bash
# Via AWS Organizations
aws organizations create-account \
  --email aws-staging@example.com \
  --account-name "Staging" \
  --role-name OrganizationAccountAccessRole

# Get account ID
ACCOUNT_ID=$(aws organizations list-accounts \
  --query 'Accounts[?Name==`Staging`].Id' \
  --output text)
```

### Step 2: Update Terraform
```terraform
# Add to environments/root/terraform.tfvars
staging_account_id = "123456789012"

# Add to modules/organization/main.tf
resource "aws_organizations_organizational_unit" "staging" {
  name      = "Staging"
  parent_id = aws_organizations_organizational_unit.workloads.id
}
```

### Step 3: Apply Changes
```bash
cd environments/root
terraform plan
terraform apply
```

### Step 4: Enroll in Control Tower
```bash
aws controltower enroll-account \
  --account-id $ACCOUNT_ID \
  --organizational-unit-id <staging-ou-id> \
  --region us-east-1
```

---

## Modifying SCPs

### Step 1: Test in Sandbox
```bash
# Create test policy
cat > test-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "TestControl",
    "Effect": "Deny",
    "Action": "ec2:RunInstances",
    "Resource": "*"
  }]
}
EOF

# Apply to sandbox account
aws organizations create-policy \
  --name test-policy \
  --type SERVICE_CONTROL_POLICY \
  --content file://test-policy.json

aws organizations attach-policy \
  --policy-id <policy-id> \
  --target-id <sandbox-account-id>
```

### Step 2: Test Operations
```bash
# Try to create EC2 instance in sandbox
aws ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t3.micro \
  --profile sandbox

# Should be denied
```

### Step 3: Update Production Policy
```bash
# Edit policy file
vim policies/scp/dev/dev-controls.json

# Validate
./scripts/validate-policies.sh

# Apply via Terraform
cd environments/root
terraform plan
terraform apply
```

### Step 4: Monitor
```bash
# Watch for AccessDenied events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ErrorCode,AttributeValue=AccessDenied \
  --max-results 50 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)
```

---

## Handling SCP Exceptions

### Request Process
1. Team submits exception request via ticket
2. Security team reviews
3. If approved, create time-limited exception

### Implementation
```bash
# Create exception policy
cat > exception-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "TemporaryException",
    "Effect": "Deny",
    "NotAction": ["ec2:*"],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:PrincipalArn": "arn:aws:iam::123456789012:role/ExceptionRole"
      }
    }
  }]
}
EOF

# Apply exception
aws organizations create-policy \
  --name temp-exception-$(date +%Y%m%d) \
  --type SERVICE_CONTROL_POLICY \
  --content file://exception-policy.json

# Set calendar reminder to remove after 30 days
```

---

## Backup Restore Procedures

### RDS Restore
```bash
# 1. List available backups
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name Default \
  --query 'RecoveryPoints[?ResourceType==`RDS`]'

# 2. Restore from backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db-$(date +%Y%m%d-%H%M) \
  --db-snapshot-identifier <snapshot-id> \
  --db-instance-class db.t3.medium

# 3. Wait for availability
aws rds wait db-instance-available \
  --db-instance-identifier restored-db-$(date +%Y%m%d-%H%M)

# 4. Update application connection string
# 5. Verify data integrity
# 6. Delete old instance after verification
```

### EBS Restore
```bash
# 1. Find snapshot
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:Name,Values=prod-data-volume"

# 2. Create volume from snapshot
aws ec2 create-volume \
  --snapshot-id <snapshot-id> \
  --availability-zone us-east-1a \
  --volume-type gp3

# 3. Attach to instance
aws ec2 attach-volume \
  --volume-id <volume-id> \
  --instance-id <instance-id> \
  --device /dev/sdf

# 4. Mount and verify
```

---

## Cost Optimization Tasks

### Weekly (30 minutes)
```bash
# 1. Identify unused EBS volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]'

# 2. Find unattached EIPs
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]'

# 3. Check for old snapshots
aws ec2 describe-snapshots \
  --owner-ids self \
  --query 'Snapshots[?StartTime<=`2025-01-01`].[SnapshotId,StartTime,VolumeSize]'

# 4. Review Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Monthly (2 hours)
- Review Savings Plans recommendations
- Right-size instances based on CloudWatch metrics
- Implement S3 lifecycle policies
- Clean up old AMIs and snapshots

---

## Compliance Auditing

### Monthly Compliance Report
```bash
# 1. Config compliance summary
aws configservice describe-compliance-by-config-rule \
  --output json > compliance-report-$(date +%Y%m).json

# 2. SCP violations
aws cloudtrail lookup-events \
  --start-time $(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%S) \
  --lookup-attributes AttributeKey=ErrorCode,AttributeValue=AccessDenied \
  --max-results 1000 > scp-violations-$(date +%Y%m).json

# 3. Root account usage
aws cloudtrail lookup-events \
  --start-time $(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%S) \
  --lookup-attributes AttributeKey=Username,AttributeValue=root \
  --max-results 100 > root-usage-$(date +%Y%m).json

# 4. Generate report
python scripts/generate-compliance-report.py
```

---

## Incident Response

### Security Incident
1. **Isolate**: Attach deny-all SCP to affected account
2. **Investigate**: Review CloudTrail logs
3. **Contain**: Rotate credentials, terminate unauthorized resources
4. **Recover**: Restore from backup if needed
5. **Document**: Post-mortem report

### Cost Spike
1. **Identify**: Check Cost Explorer by service/account
2. **Stop**: Terminate expensive resources
3. **Prevent**: Apply restrictive SCP
4. **Analyze**: Root cause analysis
5. **Improve**: Update cost controls

### SCP Lockout
1. **Verify**: Confirm SCP is the issue
2. **Detach**: Use break-glass role to detach SCP
3. **Fix**: Correct the policy
4. **Test**: Validate in sandbox
5. **Reattach**: Apply corrected policy

---

## Terraform State Management

### State Backup
```bash
# Manual backup before major changes
aws s3 cp s3://terraform-state-326698396633/control-tower/terraform.tfstate \
  ./backups/terraform.tfstate.$(date +%Y%m%d-%H%M%S)
```

### State Recovery
```bash
# List versions
aws s3api list-object-versions \
  --bucket terraform-state-326698396633 \
  --prefix control-tower/terraform.tfstate

# Restore specific version
aws s3api get-object \
  --bucket terraform-state-326698396633 \
  --key control-tower/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.restored
```

---

## Monitoring Dashboard

### Create CloudWatch Dashboard
```bash
aws cloudwatch put-dashboard \
  --dashboard-name OrganizationOps \
  --dashboard-body file://dashboard.json
```

### Key Metrics to Monitor
- SCP violations (AccessDenied events)
- Root account usage
- IAM policy changes
- Cost by account
- Config rule compliance
- Backup success rate

---

## Quarterly Tasks

### Access Review (4 hours)
- Review all IAM users and roles
- Remove unused credentials
- Verify MFA enabled
- Check for overly permissive policies

### SCP Review (2 hours)
- Review all SCPs for effectiveness
- Check for exceptions that can be removed
- Update based on new AWS services
- Test in sandbox

### Backup Testing (4 hours)
- Restore one RDS database
- Restore one EBS volume
- Verify data integrity
- Document restore time (RTO)

### Compliance Audit (8 hours)
- Run full compliance scan
- Generate audit report
- Address non-compliant resources
- Update documentation

---

## Useful Aliases

Add to `~/.bashrc`:
```bash
alias aws-costs='aws ce get-cost-and-usage --time-period Start=$(date -u -d "7 days ago" +%Y-%m-%d),End=$(date -u +%Y-%m-%d) --granularity DAILY --metrics BlendedCost --group-by Type=DIMENSION,Key=LINKED_ACCOUNT'

alias aws-alarms='aws cloudwatch describe-alarms --state-value ALARM'

alias aws-compliance='aws configservice describe-compliance-by-config-rule --compliance-types NON_COMPLIANT'

alias aws-violations='aws cloudtrail lookup-events --lookup-attributes AttributeKey=ErrorCode,AttributeValue=AccessDenied --max-results 20'
```

---

## Escalation Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| Security Incident | security@example.com | 15 min |
| Cost Spike | finance@example.com | 1 hour |
| SCP Lockout | platform-team@example.com | 30 min |
| Compliance | compliance@example.com | 4 hours |

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-17  
**Owner**: Platform Team  
**Review**: Monthly
