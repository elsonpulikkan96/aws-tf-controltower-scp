# IAM Permissions Required for Terraform

## Management Account Permissions

The IAM user or role running Terraform in the management account (326698396633) needs the following permissions:

### AWS Organizations
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "organizations:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### AWS Control Tower
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "controltower:*",
        "servicecatalog:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### IAM (for role creation)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:CreatePolicy",
        "iam:GetPolicy",
        "iam:DeletePolicy",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    }
  ]
}
```

### S3 (for Control Tower buckets and Terraform state)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::aws-controltower-*",
        "arn:aws:s3:::terraform-state-*"
      ]
    }
  ]
}
```

### CloudTrail, Config, GuardDuty
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*",
        "config:*",
        "guardduty:*",
        "securityhub:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Recommended: Use AWS Managed Policies

For simplicity during setup, you can use these AWS managed policies:
- `arn:aws:iam::aws:policy/AdministratorAccess` (for initial setup only)

For production, create a custom policy with only the permissions listed above.

## Creating the IAM User/Role

### Option 1: IAM User
```bash
aws iam create-user --user-name terraform-control-tower
aws iam attach-user-policy --user-name terraform-control-tower --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name terraform-control-tower
```

### Option 2: IAM Role (Recommended)
```bash
# Create role with trust policy for your identity
aws iam create-role --role-name TerraformControlTower --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name TerraformControlTower --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## Security Best Practices

1. **Use IAM Roles** instead of IAM users when possible
2. **Enable MFA** for the IAM user/role
3. **Rotate credentials** regularly
4. **Use least privilege** - start with admin access for setup, then reduce to minimum required
5. **Audit regularly** - review CloudTrail logs for Terraform actions
6. **Use AWS SSO** for human access to management account
