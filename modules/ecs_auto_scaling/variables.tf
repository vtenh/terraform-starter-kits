variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "max_count" {
  description = "The number of max_capacity for autoscalling group"
  default     = 4
}

variable "min_count" {
  description = "The number of min_capacity for autoscalling group"
  default     = 1
}

variable "metric_type" {
  description = "CW Metric type (CPU / Memory / RequestCount) to use to trigger auto scalling. Default to CPU. RequestCount is only available for TargetTrackingScaling poliycy"

  default = "CPU"
}

variable "target_value" {
  type    = number
  default = 75
}

variable "policy_type" {
  # TargetTrackingScaling, StepScaling
  default = "StepScaling"
}
