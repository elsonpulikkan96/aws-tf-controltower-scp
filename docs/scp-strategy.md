# SCP Strategy and Best Practices

## Overview

Service Control Policies (SCPs) are a type of organization policy that manages permissions across your AWS organization. SCPs offer central control over the maximum available permissions for all accounts in your organization.

## Key Principles

### 1. Defense in Depth
SCPs are one layer of security. Combine with:
- IAM policies
- Resource-based policies
- VPC security groups
- AWS Config rules
- GuardDuty findings

### 2. Explicit Deny Wins
- SCPs use deny-by-default logic
- An explicit deny in an SCP overrides any allow
- Management account is exempt from SCPs (except for specific services)

### 3. Inheritance
- SCPs attached to root apply to all accounts
- SCPs attached to OUs apply to all accounts in that OU and child OUs
- Multiple SCPs can apply to a single account (intersection of permissions)

## SCP Hierarchy Strategy

```
Root (Common Security Controls)
├── Security OU (Additional security restrictions)
├── Sandbox OU (Relaxed for experimentation)
└── Workloads OU (Production-grade controls)
    ├── Dev OU (Dev-specific controls)
    └── Prod OU (Strictest controls)
```

## Common SCP Patterns

### 1. Region Restriction

Limit operations to approved regions:

```json
{
  "Sid": "DenyRegionRestriction",
  "Effect": "Deny",
  "NotAction": [
    "iam:*",
    "organizations:*",
    "route53:*",
    "cloudfront:*",
    "support:*"
  ],
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:RequestedRegion": ["us-east-1", "us-west-2"]
    }
  }
}
```

**Why**: Reduce attack surface, simplify compliance, control costs

### 2. Deny Root User Access

Prevent root user from performing any actions:

```json
{
  "Sid": "DenyRootUserAccess",
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringLike": {
      "aws:PrincipalArn": "arn:aws:iam::*:root"
    }
  }
}
```

**Why**: Root user has unrestricted access; should only be used for account recovery

### 3. Require Encryption

Deny creation of unencrypted resources:

```json
{
  "Sid": "RequireEncryptedEBS",
  "Effect": "Deny",
  "Action": "ec2:RunInstances",
  "Resource": "arn:aws:ec2:*:*:volume/*",
  "Condition": {
    "Bool": {
      "ec2:Encrypted": "false"
    }
  }
}
```

**Why**: Data protection, compliance requirements

### 4. Prevent Security Service Tampering

Deny disabling security services:

```json
{
  "Sid": "DenySecurityServiceChanges",
  "Effect": "Deny",
  "Action": [
    "cloudtrail:DeleteTrail",
    "cloudtrail:StopLogging",
    "guardduty:DeleteDetector",
    "config:DeleteConfigRule",
    "securityhub:DisableSecurityHub"
  ],
  "Resource": "*"
}
```

**Why**: Maintain audit trail, prevent security blind spots

### 5. Require Resource Tagging

Deny resource creation without required tags:

```json
{
  "Sid": "RequireTagsOnResourceCreation",
  "Effect": "Deny",
  "Action": [
    "ec2:RunInstances",
    "rds:CreateDBInstance"
  ],
  "Resource": "*",
  "Condition": {
    "Null": {
      "aws:RequestTag/Environment": "true",
      "aws:RequestTag/Owner": "true"
    }
  }
}
```

**Why**: Cost allocation, resource management, compliance

## Environment-Specific Strategies

### Dev Environment

**Goals**: Enable innovation, control costs, prevent production access

**Key Controls**:
- Limit instance types to cost-effective options (t2, t3)
- Prevent access to production data
- Allow broader service access
- Require environment tagging
- Optional: Auto-shutdown outside business hours

**Risk Level**: Medium (data loss acceptable, security important)

### Prod Environment

**Goals**: Maximum security, data protection, compliance

**Key Controls**:
- Strict service allowlist
- Require encryption everywhere
- Prevent public access (S3, RDS, etc.)
- Immutable backups
- Require MFA for sensitive operations
- Prevent IAM user creation (use SSO only)
- Enable deletion protection

**Risk Level**: Low (zero tolerance for security issues)

## Testing Strategy

### 1. Test in Sandbox First
- Create a sandbox account
- Apply SCP
- Test various operations
- Verify denies work as expected

### 2. Gradual Rollout
1. Apply to single dev account
2. Monitor for 1 week
3. Apply to dev OU
4. Monitor for 1 week
5. Apply to prod OU

### 3. Break Glass Procedure
Have a documented process to quickly detach SCPs in emergency:

```bash
# Emergency SCP detachment
aws organizations detach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-xxxx-xxxxxxxx
```

## Common Pitfalls

### 1. Locking Yourself Out
**Problem**: SCP denies operations needed for management
**Solution**: Always exclude management account or specific admin roles

### 2. Overly Restrictive SCPs
**Problem**: Legitimate operations are blocked
**Solution**: Start permissive, gradually tighten based on actual usage

### 3. Conflicting Policies
**Problem**: Multiple SCPs create unexpected denies
**Solution**: Document all SCPs, use consistent naming, test combinations

### 4. Forgetting Global Services
**Problem**: Region restriction breaks IAM, CloudFront, etc.
**Solution**: Always exclude global services from region restrictions

### 5. Not Testing Terraform Operations
**Problem**: SCP blocks Terraform from managing resources
**Solution**: Test Terraform plan/apply after SCP changes

## Monitoring and Compliance

### CloudTrail Events to Monitor

```bash
# Failed API calls due to SCP
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AccessDenied \
  --max-results 50
```

### AWS Config Rules

Create Config rules to verify SCP compliance:
- `required-tags`
- `encrypted-volumes`
- `s3-bucket-public-read-prohibited`
- `rds-storage-encrypted`

### Regular Audits

Monthly checklist:
- [ ] Review CloudTrail for AccessDenied events
- [ ] Check for new AWS services that need SCP coverage
- [ ] Verify all accounts have correct SCPs attached
- [ ] Test break glass procedure
- [ ] Update documentation

## SCP Versioning

Maintain versions of SCPs:

```
policies/scp/common/
├── security-baseline.json (current)
├── security-baseline-v1.json (archived)
└── security-baseline-v2.json (archived)
```

Use git tags for major changes:
```bash
git tag -a scp-v1.0 -m "Initial SCP deployment"
git push --tags
```

## Documentation Requirements

For each SCP, document:
1. **Purpose**: Why this SCP exists
2. **Scope**: Which OUs/accounts it applies to
3. **Impact**: What operations it blocks
4. **Exceptions**: Any special cases or exclusions
5. **Owner**: Team responsible for maintaining it
6. **Review Date**: When it should be reviewed next

## Resources

- [AWS SCP Documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [SCP Examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html)
- [AWS Policy Simulator](https://policysim.aws.amazon.com/)
- [IAM Policy Validator](https://github.com/aws-cloudformation/cfn-policy-validator)
