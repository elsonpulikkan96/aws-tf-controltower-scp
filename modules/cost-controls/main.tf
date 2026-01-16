variable "accounts" {
  description = "Map of account names to IDs and budget limits"
  type = map(object({
    account_id = string
    limit      = string
  }))
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}

# Budget alerts for each account
resource "aws_budgets_budget" "account_budgets" {
  for_each = var.accounts

  name         = "${each.key}-monthly-budget"
  budget_type  = "COST"
  limit_amount = each.value.limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "LinkedAccount"
    values = [each.value.account_id]
  }

  notification {
    threshold             = 80
    comparison_operator   = "GREATER_THAN"
    threshold_type        = "PERCENTAGE"
    notification_type     = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    threshold             = 100
    comparison_operator   = "GREATER_THAN"
    threshold_type        = "PERCENTAGE"
    notification_type     = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    threshold             = 90
    comparison_operator   = "GREATER_THAN"
    threshold_type        = "PERCENTAGE"
    notification_type     = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# Cost anomaly detection
resource "aws_ce_anomaly_monitor" "org_monitor" {
  name              = "organization-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "anomaly_alerts" {
  name      = "cost-anomaly-alerts"
  frequency = "DAILY"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.org_monitor.arn,
  ]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["100"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
