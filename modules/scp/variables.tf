variable "policy_name" {
  description = "Name of the SCP"
  type        = string
}

variable "policy_description" {
  description = "Description of the SCP"
  type        = string
}

variable "policy_file" {
  description = "Path to the JSON policy file"
  type        = string
}

variable "target_ids" {
  description = "List of OU or account IDs to attach the policy to"
  type        = list(string)
}
