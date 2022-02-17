resource "aws_appautoscaling_target" "main" {
  service_namespace = "ecs"

  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_count
  max_capacity       = var.max_count
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-configure-auto-scaling.html
//=========================== Target Tracking Scaling ===================================================
resource "aws_appautoscaling_policy" "main_target_tracking" {
  count              = var.policy_type == "TargetTrackingScaling" ? 1 : 0
  name               = "${var.cluster_name}-target-tracking-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      # ECSServiceAverageCPUUtilization, ECSServiceAverageMemoryUtilization, ALBRequestCountPerTarget
      predefined_metric_type = local.predefined_metric_type
    }
    # A target tracking scaling policy assumes that it should perform scale out when the specified metric is above the target value
    # number_of_request / percentage.
    target_value = var.target_value

    # number_of_second
    scale_in_cooldown  = 120
    scale_out_cooldown = 120
  }
}

//======================= Policy Step scaling =============================================
resource "aws_appautoscaling_policy" "main_scale_up" {
  count = var.policy_type == "StepScaling" ? 1 : 0

  name               = "${var.cluster_name}-scale-up"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "main_scale_down" {
  count              = var.policy_type == "StepScaling" ? 1 : 0
  name               = "${var.cluster_name}-scale-down"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
############################# Trigger auto scalling from CW metric ################################
#============================ Memory Variant ======================================================
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.metric_type == "Memory" ? 1 : 0
  alarm_name          = "${var.cluster_name}-High Memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.target_value

  alarm_actions = [
    aws_appautoscaling_policy.main_scale_up[0].arn
  ]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  count               = var.metric_type == "Memory" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Low Memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"

  alarm_actions = [
    aws_appautoscaling_policy.main_scale_down[0].arn
  ]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

}
#============================ CPU Variant ======================================================

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.metric_type == "CPU" ? 1 : 0
  alarm_name          = "${var.cluster_name}-High CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.target_value

  alarm_actions = [
    aws_appautoscaling_policy.main_scale_up[0].arn
  ]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.metric_type == "CPU" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Low CPU"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  alarm_actions = [
    aws_appautoscaling_policy.main_scale_down[0].arn
  ]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}
