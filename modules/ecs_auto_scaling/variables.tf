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
  description = "CW Metric type (CPU or Memory) to use to trigger auto scalling. Default to CPU"
  default     = "CPU"
}
