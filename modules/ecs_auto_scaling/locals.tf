locals {
  predefined_metric_types = {
    # ECSServiceAverageCPUUtilization, ECSServiceAverageMemoryUtilization, ALBRequestCountPerTarget
    CPU          = "ECSServiceAverageCPUUtilization"
    Memory       = "ECSServiceAverageMemoryUtilization"
    RequestCount = "ALBRequestCountPerTarget"
  }

  predefined_metric_type = local.predefined_metric_types[var.metric_type]
}
