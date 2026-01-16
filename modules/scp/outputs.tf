output "policy_id" {
  description = "SCP Policy ID"
  value       = aws_organizations_policy.scp.id
}

output "policy_arn" {
  description = "SCP Policy ARN"
  value       = aws_organizations_policy.scp.arn
}
