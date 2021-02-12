variable "default_tags" {
  default = {}
}
variable "name" {
  description = "Ecs fargate name"
  type        = string
}
variable "container_insights" {
  type    = bool
  default = true
}
variable "cpu" {
  description = "The number of CPU value. 1024 is equal 1CPU unit"
  type        = string
}
variable "memory" {
  description = "Then number of memory in MB"
  type        = string
}

variable "container_definitions" {
  description = "Container definition. data.template_file.container_def.rendered"
  type        = string
}

variable "task_role_arn" {
  type = string
}
variable "execution_role_arn" {
  type = string
}

variable "desired_count" {
  description = "The number of desired containers"
  default     = 1
}

variable "security_group_ids" {
  description = "List of security group id. e.g  aws_security_group.main.id "
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet id"
  type        = list
}

variable "use_load_balancer" {
  default = true
}
variable "target_group_arn" {

  description = "elastic load balancer target group arn. Optional if use_load_balancer is false "
  type        = string
  default     = ""

}

variable "container_name" {
  description = "Optional if use_load_balancer is false"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Optional if use_load_balancer is false"
  default     = 80
}
