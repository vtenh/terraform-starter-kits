data "aws_rds_engine_version" "postgresql" {
  engine = "postgres"
}

resource "aws_db_subnet_group" "main" {
  name_prefix = "main"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_kms_key" "insight_key" {
  description = "KMS key for RDS performance insight"
  is_enabled  = true

  tags = {
    Name = "KMSKEY postgresqlInsight"
  }
}

resource "aws_db_instance" "postgresql" {
  identifier = "${var.identifier}-postgresql"

  storage_type          = "gp2"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = false

  engine = var.engine
  # engine_version = var.engine_version
  instance_class = var.postgresql_engine_class

  multi_az = true

  name     = var.postgresql_db_name
  username = var.postgresql_db_username
  password = var.postgresql_db_password

  backup_retention_period = 7

  db_subnet_group_name = aws_db_subnet_group.main.name
  deletion_protection  = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  performance_insights_kms_key_id       = aws_kms_key.insight_key.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  vpc_security_group_ids = var.security_group_ids

  final_snapshot_identifier = "${var.identifier}-postgresql"
  skip_final_snapshot       = false

}

# resource "aws_db_instance" "postgresql_replica" {
#   count      = length(var.replica_ids)
#   identifier = "${var.identifier}-postgresql-${var.replica_ids[count.index]}"

#   storage_type   = "gp2"
#   allocated_storage     = var.allocated_storage
#   max_allocated_storage = var.max_allocated_storage
#   storage_encrypted     = false

#   # Source database. For cross-region use db_instance_arn
#   replicate_source_db = aws_db_instance.postgresql.identifier
#   engine              = var.engine
#   engine_version      = var.engine_version

#   instance_class = var.replica_postgresql_engine_class

#   multi_az               = true

#   deletion_protection  = false

#   enabled_cloudwatch_logs_exports = ["postgresql"]

#   performance_insights_kms_key_id       = aws_kms_key.insight_key.arn
#   performance_insights_enabled          = true
#   performance_insights_retention_period = 7

#   vpc_security_group_ids = var.replica_security_group_ids
#   publicly_accessible = false

# }
