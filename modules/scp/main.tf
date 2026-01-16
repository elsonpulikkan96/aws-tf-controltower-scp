resource "aws_organizations_policy" "scp" {
  name        = var.policy_name
  description = var.policy_description
  type        = "SERVICE_CONTROL_POLICY"
  content     = file(var.policy_file)
}

resource "aws_organizations_policy_attachment" "scp_attachment" {
  for_each = toset(var.target_ids)
  
  policy_id = aws_organizations_policy.scp.id
  target_id = each.value
}
