variable "cluster_name" {
  type = string
}
variable "cpu" {
  type = string
}

variable "memory" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "desired_count" {
  default = 1
}

variable "min_capacity" {
  default = 0
}

variable "max_capacity" {
  default = 1
}

variable "execution_role_arn" {
  type = string
}
# Required if is_scheduled_task is false
variable "tasks" {
  type = list(object({
    container_definitions = string
    expression_start      = string
    name                  = string
  }))

  default = []
}

# Required if is_scheduled_task is true
variable "scheduled_tasks" {
  # expression_start = "cron(min hour day-of-month month day-of-week year). Required if is_scheduled_task is false"
  # expression_stop =  "cron(min hour day-of-month month day-of-week year). optional if is_scheduled_task. Required if is_scheduled_task is true"
  type = list(object({
    container_definitions = string
    expression_start      = string
    name                  = string
  }))

  default = []
}


variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "is_public_subnet" {
  default = false
}

variable "is_scheduled_task" {
  default = true
}
