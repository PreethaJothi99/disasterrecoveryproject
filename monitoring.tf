# ===== SNS Topic & Email Subscription =====
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ===== ALB (Primary) unhealthy targets > 0 for 5 minutes =====
resource "aws_cloudwatch_metric_alarm" "alb_a_unhealthy" {
  alarm_name          = "${var.project_name}-alb-a-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  dimensions = {
    LoadBalancer = aws_lb.a.arn_suffix
    TargetGroup  = aws_lb_target_group.a.arn_suffix
  }
  alarm_description   = "Primary ALB has unhealthy targets"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ===== ASG (Primary) fewer than 2 instances in service =====
resource "aws_cloudwatch_metric_alarm" "asg_a_low" {
  alarm_name          = "${var.project_name}-asg-a-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.a.name
  }
  alarm_description   = "Primary ASG has < 2 instances in service"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ===== RDS Primary: CPU > 80% for 10 minutes =====
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-a-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
  alarm_description   = "RDS CPU high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ===== RDS Primary: Free storage < 2 GB =====
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-a-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2 * 1024 * 1024 * 1024
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
  alarm_description   = "RDS free storage < 2GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
