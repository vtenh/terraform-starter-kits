variable "name" {
  description = "Ecs fargate name"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group id. e.g  aws_security_group.main.id "
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet id"
  type        = list
}

variable "default_tags" {
  default = {}
}

variable "container_port" {
  default = 80
}

variable "vpc_id" {
  description = "The id of your vpc. e.g. aws_vpc.main.id"
  type        = string
}

variable "health_check_path" {
  description = "Health check path of your http. e.g /health_check"

  default = "/health_check"
}

variable "acm_certificate_arn" {
  description = "The ARN of your SSL cert from ACM"
  type        = string
}

variable "domain_name" {
  description = "The domain name. e.g vtenh.com"
  type        = string
}
