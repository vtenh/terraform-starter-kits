variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  description = "security group id for master"
  type        = list(string)
}

variable "replica_security_group_ids" {
  description = "replica_security_group_ids"
  type        = list(string)
}

variable "identifier" {
  type = string
}

variable "postgresql_db_name" {
  type = string
}

variable "postgresql_db_username" {
  type = string
}

variable "postgresql_db_password" {
  type = string
}

variable "postgresql_engine_version" {
  description = "Engine version, default to the latest version"
  default     = ""
}

variable "postgresql_engine_class" {
  default = "db.t3.medium"
}

variable "replica_postgresql_engine_class" {
  default = "db.t3.micro"
}

variable "engine" {
  default = "postgres"
}
variable "engine_version" {
  default = "12.5"
}

variable "replica_ids" {
  default = []
  type    = list(string)
}

variable "allocated_storage" {
  default = 20
}

variable "max_allocated_storage" {
  default = 200
}
