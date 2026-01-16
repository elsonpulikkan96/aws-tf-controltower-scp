variable "alert_email" {
  description = "Email for operational alerts"
  type        = string
}

# SNS topic for operational alerts
resource "aws_sns_topic" "ops_alerts" {
  name = "operational-alerts"
}

resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group for CloudTrail metrics
resource "aws_cloudwatch_log_metric_filter" "scp_violations" {
  name           = "scp-access-denied"
  log_group_name = "/aws/cloudtrail/organization"
  pattern        = "{ $.errorCode = \"AccessDenied\" || $.errorCode = \"UnauthorizedOperation\" }"

  metric_transformation {
    name      = "SCPViolations"
    namespace = "Security"
    value     = "1"
  }
}

# Alarm for SCP violations
resource "aws_cloudwatch_metric_alarm" "scp_violations" {
  alarm_name          = "high-scp-violations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SCPViolations"
  namespace           = "Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when SCP blocks exceed threshold"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
}

# Alarm for root account usage
resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  name           = "root-account-usage"
  log_group_name = "/aws/cloudtrail/organization"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name          = "root-account-usage-detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountUsage"
  namespace           = "Security"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert on any root account usage"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
}

# Alarm for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_calls" {
  name           = "unauthorized-api-calls"
  log_group_name = "/aws/cloudtrail/organization"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_calls" {
  alarm_name          = "high-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "20"
  alarm_description   = "Alert on high unauthorized API calls"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
}

# Alarm for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "iam-policy-changes"
  log_group_name = "/aws/cloudtrail/organization"
  pattern        = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }"

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  alarm_name          = "iam-policy-changes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert on IAM policy changes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
}

output "sns_topic_arn" {
  description = "SNS topic ARN for operational alerts"
  value       = aws_sns_topic.ops_alerts.arn
}
