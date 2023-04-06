resource "aws_sns_topic" "billing_alarms" {
  name_prefix       = "billing-alarms-"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "billing_alarm_subscription" {
  topic_arn = aws_sns_topic.billing_alarms.arn
  protocol  = "email"
  endpoint  = var.account_admin_email
}

resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "account-billing-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600" # 6 hours
  statistic           = "Maximum"
  threshold           = var.monthly_billing_threshold
  alarm_actions       = [aws_sns_topic.billing_alarms.arn]

  dimensions = {
    Currency = "USD"
  }
}

resource "aws_budgets_budget" "min_spend" {
  name         = "min-spend-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 5
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.account_admin_email]
  }
}

resource "aws_sns_topic" "health_alarms" {
  name_prefix       = "health-alarms-"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "health_alarm_subscription" {
  topic_arn = aws_sns_topic.health_alarms.arn
  protocol  = "email"
  endpoint  = var.account_admin_email
}

resource "aws_cloudwatch_event_rule" "aws_health" {
  name        = "capture-aws-health-events"
  description = "Capture AWS Health Events"

  event_pattern = <<-EOF
  {
    "source": ["aws.health"],
    "detail-type": ["AWS Health Event"]
  }
  EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.aws_health.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.health_alarms.arn
}
