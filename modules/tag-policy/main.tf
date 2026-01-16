resource "aws_organizations_policy" "tag_policy" {
  name        = "required-tags-policy"
  description = "Enforce required tags across organization"
  type        = "TAG_POLICY"
  content     = file(var.policy_file)
}

resource "aws_organizations_policy_attachment" "tag_policy_attachment" {
  for_each = toset(var.target_ids)
  
  policy_id = aws_organizations_policy.tag_policy.id
  target_id = each.value
}
