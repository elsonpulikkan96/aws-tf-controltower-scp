# Break-Glass Emergency Procedures

## 🚨 EMERGENCY CONTACTS

**Primary On-Call**: [Your Team Lead]  
**Secondary On-Call**: [Backup Contact]  
**AWS Support**: Enterprise Support Case  
**Management Escalation**: [CTO/VP Engineering]

---

## 🔥 SCENARIO 1: SCP Lockout

### Symptoms:
- Terraform operations failing with AccessDenied
- Unable to create/modify resources
- Legitimate operations blocked

### Immediate Actions:

1. **Identify the blocking SCP**:
```bash
# Check which SCPs are attached
aws organizations list-policies-for-target \
  --target-id <ou-id> \
  --filter SERVICE_CONTROL_POLICY

# Review recent SCP changes in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AttachPolicy \
  --max-results 10
```

2. **Detach the problematic SCP** (Management account only):
```bash
# Detach from OU
aws organizations detach-policy \
  --policy-id <policy-id> \
  --target-id <ou-id>

# Verify detachment
aws organizations list-policies-for-target \
  --target-id <ou-id> \
  --filter SERVICE_CONTROL_POLICY
```

3. **Test operations**:
```bash
# Try the previously blocked operation
terraform plan
```

4. **Fix and reattach**:
- Fix the SCP JSON
- Test in sandbox first
- Reattach to production

### Prevention:
- Always test SCPs in sandbox first
- Exclude management account from restrictive SCPs
- Keep break-glass IAM role with SCP detach permissions

---

## 🔥 SCENARIO 2: Account Compromise

### Symptoms:
- Unusual API calls in CloudTrail
- GuardDuty findings
- Unauthorized resource creation
- Unexpected costs

### Immediate Actions:

1. **Isolate the account**:
```bash
# Attach deny-all SCP
aws organizations attach-policy \
  --policy-id <deny-all-policy-id> \
  --target-id <compromised-account-id>
```

2. **Rotate all credentials**:
```bash
# List all IAM users
aws iam list-users --query 'Users[*].UserName'

# Deactivate access keys
aws iam update-access-key \
  --user-name <username> \
  --access-key-id <key-id> \
  --status Inactive

# Force password reset
aws iam update-login-profile \
  --user-name <username> \
  --password-reset-required
```

3. **Review CloudTrail logs**:
```bash
# Find suspicious activity
aws cloudtrail lookup-events \
  --start-time $(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --max-results 100 \
  --query 'Events[?Username!=`expected-user`]'
```

4. **Terminate unauthorized resources**:
```bash
# List recent EC2 instances
aws ec2 describe-instances \
  --filters "Name=launch-time,Values=$(date -u -d '2 hours ago' +%Y-%m-%d)*" \
  --query 'Reservations[*].Instances[*].[InstanceId,LaunchTime]'

# Terminate if unauthorized
aws ec2 terminate-instances --instance-ids <instance-id>
```

5. **Open AWS Support case** (Enterprise Support)

### Post-Incident:
- Full security audit
- Review IAM policies
- Enable MFA on all accounts
- Update incident response plan

---

## 🔥 SCENARIO 3: Terraform State Corruption

### Symptoms:
- Terraform plan shows unexpected changes
- State file errors
- Resources out of sync

### Immediate Actions:

1. **Stop all Terraform operations**:
```bash
# Alert team via Slack/email
# Lock state file if using Terraform Cloud
```

2. **Backup current state**:
```bash
# Download from S3
aws s3 cp s3://terraform-state-326698396633/control-tower/terraform.tfstate \
  ./terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)

# List versions
aws s3api list-object-versions \
  --bucket terraform-state-326698396633 \
  --prefix control-tower/terraform.tfstate
```

3. **Restore from backup**:
```bash
# Restore previous version
aws s3api get-object \
  --bucket terraform-state-326698396633 \
  --key control-tower/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.restored

# Upload restored state
aws s3 cp terraform.tfstate.restored \
  s3://terraform-state-326698396633/control-tower/terraform.tfstate
```

4. **Verify state**:
```bash
cd environments/root
terraform init
terraform plan  # Should show no changes
```

### Prevention:
- Enable S3 versioning (already done)
- Set up cross-region replication
- Regular state backups
- Use Terraform Cloud for state management

---

## 🔥 SCENARIO 4: Control Tower Failure

### Symptoms:
- Control Tower console shows errors
- Guardrails not enforcing
- Account enrollment failing

### Immediate Actions:

1. **Check Control Tower status**:
```bash
aws controltower list-landing-zones --region us-east-1
```

2. **Review CloudTrail for Control Tower events**:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=controltower.amazonaws.com \
  --max-results 50
```

3. **Open AWS Support case** (Priority: Urgent)

4. **Temporary workaround**:
- Apply SCPs directly (bypass Control Tower)
- Manual account configuration
- Document all manual changes

### Recovery:
- Follow AWS Support guidance
- May require Control Tower reset
- Re-enroll accounts after recovery

---

## 🔥 SCENARIO 5: Cost Spike

### Symptoms:
- Budget alert triggered
- Unexpected AWS bill
- Cost anomaly detection alert

### Immediate Actions:

1. **Identify the source**:
```bash
# Check Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Check by account
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=LINKED_ACCOUNT
```

2. **Stop expensive resources**:
```bash
# Stop all EC2 instances in dev
aws ec2 stop-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=dev" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

# Delete large S3 objects
aws s3 ls s3://bucket-name --recursive --human-readable --summarize
```

3. **Apply emergency cost controls**:
```bash
# Attach restrictive SCP to dev OU
aws organizations attach-policy \
  --policy-id <cost-control-policy-id> \
  --target-id <dev-ou-id>
```

4. **Review and optimize**:
- Right-size instances
- Delete unused resources
- Enable Savings Plans

---

## 🔥 SCENARIO 6: Backup Restore Needed

### Symptoms:
- Data loss
- Accidental deletion
- Corruption

### Immediate Actions:

1. **Identify backup**:
```bash
# List available backups
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name Default \
  --query 'RecoveryPoints[?ResourceType==`RDS`]'
```

2. **Restore from backup**:
```bash
# RDS restore
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db-$(date +%Y%m%d) \
  --db-snapshot-identifier <snapshot-id>

# EBS restore
aws ec2 create-volume \
  --snapshot-id <snapshot-id> \
  --availability-zone us-east-1a
```

3. **Verify restore**:
- Test database connectivity
- Verify data integrity
- Check application functionality

4. **Document incident**:
- What was lost
- How it was restored
- Lessons learned

---

## 📞 ESCALATION MATRIX

| Severity | Response Time | Escalation Path |
|----------|--------------|-----------------|
| P1 (Critical) | 15 minutes | On-Call → Team Lead → VP Eng → CTO |
| P2 (High) | 1 hour | On-Call → Team Lead |
| P3 (Medium) | 4 hours | On-Call |
| P4 (Low) | Next business day | Team Lead |

---

## 🔑 BREAK-GLASS IAM ROLE

### Create Emergency Access Role:

```terraform
resource "aws_iam_role" "break_glass" {
  name = "BreakGlassEmergencyAccess"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::326698396633:root"
      }
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "break_glass_admin" {
  role       = aws_iam_role.break_glass.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

### Usage:
```bash
# Assume break-glass role (requires MFA)
aws sts assume-role \
  --role-arn arn:aws:iam::326698396633:role/BreakGlassEmergencyAccess \
  --role-session-name emergency-$(date +%Y%m%d-%H%M%S) \
  --serial-number arn:aws:iam::326698396633:mfa/your-mfa-device \
  --token-code 123456
```

---

## 📋 POST-INCIDENT CHECKLIST

After resolving any incident:

- [ ] Document what happened
- [ ] Document what was done
- [ ] Update runbooks
- [ ] Conduct post-mortem
- [ ] Implement preventive measures
- [ ] Update monitoring/alerts
- [ ] Train team on lessons learned
- [ ] Update this document

---

## 🧪 TESTING PROCEDURES

**Test break-glass procedures quarterly**:

1. Simulate SCP lockout (in sandbox)
2. Practice state restore
3. Test backup restore
4. Verify escalation contacts
5. Update documentation

**Last Tested**: [DATE]  
**Next Test Due**: [DATE]

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-17  
**Owner**: Platform Team  
**Review Frequency**: Quarterly
