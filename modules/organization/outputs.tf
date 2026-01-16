output "workloads_ou_id" {
  description = "Workloads OU ID"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "dev_ou_id" {
  description = "Dev OU ID"
  value       = aws_organizations_organizational_unit.dev.id
}

output "prod_ou_id" {
  description = "Prod OU ID"
  value       = aws_organizations_organizational_unit.prod.id
}

output "dev_account_id" {
  description = "Dev Account ID"
  value       = aws_organizations_account.dev.id
}

output "prod_account_id" {
  description = "Prod Account ID"
  value       = aws_organizations_account.prod.id
}

output "security_ou_id" {
  description = "Security OU ID"
  value       = aws_organizations_organizational_unit.security.id
}

output "sandbox_ou_id" {
  description = "Sandbox OU ID"
  value       = aws_organizations_organizational_unit.sandbox.id
}
