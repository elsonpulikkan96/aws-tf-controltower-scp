variable "aws_region" {
  description = "Primary AWS region for Control Tower"
  type        = string
  default     = "us-east-1"
}

variable "root_account_id" {
  description = "AWS Organization root/management account ID"
  type        = string
}

variable "dev_account_id" {
  description = "Development account ID"
  type        = string
}

variable "prod_account_id" {
  description = "Production account ID"
  type        = string
}

variable "additional_regions" {
  description = "Additional regions to enable for Control Tower"
  type        = list(string)
  default     = ["us-west-2", "eu-west-1"]
}

variable "allowed_regions" {
  description = "Regions allowed for resource creation"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "ops_alert_email" {
  description = "Email address for operational alerts"
  type        = string
  default     = "ops-alerts@example.com"
}
