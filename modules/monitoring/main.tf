##############################################################################
# modules/monitoring/main.tf
# CloudWatch alarms for EKS cluster health and worker node metrics.
##############################################################################

# ── SNS Topic for Alerts ──────────────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  count = var.enable_alerting ? 1 : 0
  name  = "${var.cluster_name}-eks-alerts"

  kms_master_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.enable_alerting && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  count = var.enable_alerting ? 1 : 0

  alarm_name          = "${var.cluster_name}-node-cpu-high"
  alarm_description   = "EKS node CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "${var.cluster_name}-general"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  count = var.enable_alerting ? 1 : 0

  alarm_name          = "${var.cluster_name}-node-memory-high"
  alarm_description   = "EKS node memory utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "eks" {
  dashboard_name = "${var.cluster_name}-eks"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node CPU Utilization"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.cluster_name}-general"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node Network In/Out"
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", "${var.cluster_name}-general"],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${var.cluster_name}-general"],
          ]
        }
      },
    ]
  })
}

# ── Container Insights (EKS Enhanced Monitoring) ──────────────────────────────

resource "aws_cloudwatch_log_group" "container_insights" {
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
