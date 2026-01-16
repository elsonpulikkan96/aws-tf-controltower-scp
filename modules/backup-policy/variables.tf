variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "policy_file" {
  description = "Path to the backup policy JSON file"
  type        = string
}

variable "target_ids" {
  description = "List of OU or account IDs to attach the policy to"
  type        = list(string)
}
