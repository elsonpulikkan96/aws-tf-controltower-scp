resource "aws_organizations_policy" "backup_policy" {
  name        = "${var.environment}-backup-policy"
  description = "Backup policy for ${var.environment} environment"
  type        = "BACKUP_POLICY"
  content     = file(var.policy_file)
}

resource "aws_organizations_policy_attachment" "backup_policy_attachment" {
  for_each = toset(var.target_ids)
  
  policy_id = aws_organizations_policy.backup_policy.id
  target_id = each.value
}
