output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = data.aws_organizations_organization.main.arn
}

output "root_ou_id" {
  description = "Root OU ID"
  value       = data.aws_organizations_organization.main.roots[0].id
}

output "dev_ou_id" {
  description = "Development OU ID"
  value       = module.organization.dev_ou_id
}

output "prod_ou_id" {
  description = "Production OU ID"
  value       = module.organization.prod_ou_id
}

output "common_scp_id" {
  description = "Common SCP Policy ID"
  value       = module.scp_common.policy_id
}

output "dev_scp_id" {
  description = "Dev SCP Policy ID"
  value       = module.scp_dev.policy_id
}

output "prod_scp_id" {
  description = "Prod SCP Policy ID"
  value       = module.scp_prod.policy_id
}
