variable "policy_file" {
  description = "Path to the tag policy JSON file"
  type        = string
}

variable "target_ids" {
  description = "List of OU or account IDs to attach the policy to"
  type        = list(string)
}
