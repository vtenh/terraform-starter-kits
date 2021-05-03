module "vpc" {
  source = "./modules/vpc"

  name   = var.name
  region = var.aws.credentials.region

  default_tags = local.default_tags
}

module "sg" {
  source   = "./modules/security_group"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr

  default_tags = local.default_tags
}

module "rds" {
  source                    = "./modules/rds"
  identifier                = "db"
  postgresql_engine_class   = var.rds.postgresql.engine_class
  postgresql_engine_version = var.rds.postgresql.engine_version
  postgresql_db_name        = var.rds.postgresql.db_name
  postgresql_db_username    = var.rds.postgresql.db_username
  postgresql_db_password    = var.rds.postgresql.db_password
  subnet_ids                = module.vpc.private_subnet_ids
  security_group_ids        = [module.sg.postgresql.id]
}

module "redis" {
  source               = "./modules/elasticache_redis"
  identifier           = "redis"
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.sg.redis.id]
  node_type            = "cache.t3.small"
  engine_version       = "6.0.5"
  parameter_group_name = "default.redis6.x"
}

module "memcached" {
  source               = "./modules/elasticache_memcached"
  identifier           = "memcached"
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.sg.memcached.id]
  node_type            = "cache.t3.small"
  engine_version       = "1.6.6"
  parameter_group_name = "default.memcached1.6"
}

module "s3_storage" {
  source      = "./modules/s3"
  bucket_name = var.s3_storage.bucket_name
  sites       = local.s3_cors_sites
}

module "s3_storage_dev" {
  source      = "./modules/s3"
  bucket_name = "${var.s3_storage.bucket_name}-dev"
  sites       = local.s3_cors_sites
}

module "s3_storage_staging" {
  source      = "./modules/s3"
  bucket_name = "${var.s3_storage.bucket_name}-staging"
  sites       = local.s3_cors_sites
}

# EC2 instance access key name
resource "aws_ecr_repository" "main" {
  name                 = lower(var.name)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = var.name
  public_key = file(var.ssh_public_key_file)
}

resource "aws_ssm_parameter" "ssh_public_key" {
  name  = "ssh_public_key"
  type  = "SecureString"
  value = file(var.ssh_public_key_file)

  lifecycle {
    ignore_changes = [value]
  }
}

module "iam_ecs" {
  source = "./modules/ecs_role"
  name   = lower(var.name)
}

################################ ECS EC2 ######################################

# resource "aws_cloudwatch_log_group" "ec2" {
#   name_prefix       = "/ecs/vtenh-ec2"
#   retention_in_days = 7

#   tags = {
#     "ecs_ec2_log" = "ec2 module"
#   }
# }

# data "template_file" "ecs_ec2" {
#   template = file("template/container_def.json.tpl")
#   vars = merge(local.web_container_template_vars, {
#     "container_name" = local.ecs_ec2_app_name
#     "log_group_name" = aws_cloudwatch_log_group.ec2.name
#   })
# }

# module "ecs_ec2" {
#   source                = "./modules/ecs_ec2"
#   name                  = local.ecs_ec2_app_name
#   task_cpu              = var.web_cpu
#   task_memory           = var.web_memory
#   image_id              = var.image_id
#   instance_type         = var.instance_type
#   vpc_id                = module.vpc.vpc_id
#   security_group_ids    = [module.sg.ecs.id]
#   subnet_ids            = module.vpc.public_subnet_ids
#   key_name              = aws_key_pair.ec2.key_name
#   max_count             = var.max_count
#   min_count             = var.min_count
#   desired_count         = var.desired_count
#   container_port        = var.container_port
#   iam_instance_profile  = module.iam_ecs.instance_profile_name
#   execution_role_arn    = module.iam_ecs.execution_role_arn
#   task_role_arn         = module.iam_ecs.task_role_arn
#   container_definitions = data.template_file.ecs_ec2.rendered
#   metric_type           = "CPU"
# }

# ============================= END  ECS EC2 =====================================


################################# Fargate #########################################
resource "aws_cloudwatch_log_group" "fargate" {
  name              = "/ecs/vtenh-web"
  retention_in_days = 7

  tags = {
    "ecs_fargate_log" = "fargate"
  }
}

data "template_file" "ecs_fargate" {
  template = file("template/container_def.json.tpl")
  vars = merge(local.web_container_template_vars, {
    "container_name" = local.ecs_fargate_app_name
    "log_group_name" = aws_cloudwatch_log_group.fargate.name
  })
}
module "ecs_fargate_alb" {
  source              = "./modules/ecs_alb"
  name                = local.ecs_fargate_app_name
  security_group_ids  = [module.sg.ecs.id]
  subnet_ids          = module.vpc.public_subnet_ids
  vpc_id              = module.vpc.vpc_id
  health_check_path   = var.health_check_path
  container_port      = var.container_port
  acm_certificate_arn = var.acm_certificate_arn
  domain_name         = var.domain_name
}

module "ecs_fargate" {
  source                = "./modules/ecs_fargate"
  name                  = local.ecs_fargate_app_name
  cpu                   = var.web_cpu
  memory                = var.web_memory
  container_definitions = data.template_file.ecs_fargate.rendered
  task_role_arn         = module.iam_ecs.task_role_arn
  execution_role_arn    = module.iam_ecs.execution_role_arn
  desired_count         = 2 # var.desired_count
  security_group_ids    = [module.sg.ecs.id]
  subnet_ids            = module.vpc.public_subnet_ids

  use_load_balancer = true
  target_group_arn  = module.ecs_fargate_alb.target_group_arn
  container_name    = local.ecs_fargate_app_name
  container_port    = var.container_port
}

module "ecs_fargate_auto_scaling" {
  source       = "./modules/ecs_auto_scaling"
  cluster_name = module.ecs_fargate.cluster_name
  service_name = module.ecs_fargate.service_name
  max_count    = 8 #var.max_count
  min_count    = 2 #var.min_count
  metric_type  = "CPU"
}

module "route53" {
  source            = "./modules/route53"
  domain_name       = var.domain_name
  lb_dns_name       = module.ecs_fargate_alb.lb_dns_name
  lb_zone_id        = module.ecs_fargate_alb.lb_zone_id
  sendgrid_settings = var.sendgrid_dns_settings
  cdn               = var.cdn
}
#===================================== End Fargate ===============================



################################# QUEUE  #########################################
resource "aws_cloudwatch_log_group" "ecs_queue" {
  name              = "/ecs/vtenh-queue"
  retention_in_days = 7

  tags = {
    "ecs_queue_log" = "ecs_queue"
  }
}

data "template_file" "ecs_queue" {
  template = file("template/container_def.json.tpl")
  vars = merge(local.queue_container_template_vars, {
    "container_name" = local.ecs_queue_name
    "log_group_name" = aws_cloudwatch_log_group.ecs_queue.name
  })
}
module "ecs_queue" {
  source                = "./modules/ecs_fargate"
  name                  = "ECS-Queue"
  cpu                   = var.queue_cpu
  memory                = var.queue_memory
  container_definitions = data.template_file.ecs_queue.rendered
  task_role_arn         = module.iam_ecs.task_role_arn
  execution_role_arn    = module.iam_ecs.execution_role_arn
  desired_count         = var.queue_desired_count
  security_group_ids    = [module.sg.ecs.id]
  subnet_ids            = module.vpc.public_subnet_ids
  use_load_balancer     = false
}

module "ecs_queue_auto_scaling" {
  source       = "./modules/ecs_auto_scaling"
  cluster_name = module.ecs_queue.cluster_name
  service_name = module.ecs_queue.service_name
  max_count    = var.queue_max_count
  min_count    = var.queue_min_count
  metric_type  = "CPU"
}

#===================================== End Queue ===============================



################################### CRON ######################################
resource "aws_cloudwatch_log_group" "cron" {
  name_prefix       = "/ecs/cron"
  retention_in_days = 7

  tags = {
    "ecs_schedule_task_log" = "cron"
  }
}

# task: sitemap:refresh
data "template_file" "sitemap" {
  template = file("template/container_def.json.tpl")

  # custom command with sitemap
  vars = merge(local.scheduled_task_container_template_vars, {
    "rails_task_name" = "sitemap:refresh"
    "container_name"  = local.ecs_fargate_cron
    "log_group_name"  = aws_cloudwatch_log_group.cron.name
  })
}

# task: "db:sessions:trim"
data "template_file" "session_store_ttl" {
  template = file("template/container_def.json.tpl")

  # custom command with sitemap
  vars = merge(local.scheduled_task_container_template_vars, {
    "rails_task_name" = "db:sessions:trim"
    "container_name"  = local.ecs_fargate_cron
    "log_group_name"  = aws_cloudwatch_log_group.cron.name
  })
}

module "ecs_scheduele_cron" {
  source            = "./modules/ecs_run_task"
  cluster_name      = local.ecs_fargate_cron
  is_scheduled_task = true
  scheduled_tasks = [
    { container_definitions = data.template_file.sitemap.rendered
      expression_start      = "cron(0 17 * * ? *)"
      name                  = "sitemap"
    },
    { container_definitions = data.template_file.session_store_ttl.rendered
      expression_start      = "cron(0 17 * * ? *)"
      name                  = "session_store_ttl"
    }
  ]
  execution_role_arn = module.iam_ecs.execution_role_arn
  task_role_arn      = module.iam_ecs.task_role_arn
  cpu                = var.task_cpu
  memory             = var.task_memory
  security_group_ids = [module.sg.ecs.id]
  subnet_ids         = module.vpc.private_subnet_ids
  is_public_subnet   = false
  desired_count      = 0
  min_capacity       = 0
  max_capacity       = 0
}
#=============================== End CRON ======================================



############################ Run Migration One off task #############################
resource "aws_cloudwatch_log_group" "migration" {
  name_prefix       = "/ecs/migration"
  retention_in_days = 7

  tags = {
    "ecs_schedule_task_log" = "migration"
  }
}
data "template_file" "db_migration" {
  template = file("template/container_def.json.tpl")

  # custom command with db_migration
  vars = merge(local.scheduled_task_container_template_vars, {
    "rails_task_name" = "db:migrate"
    "container_name"  = local.ecs_fargate_db_migration
    "log_group_name"  = aws_cloudwatch_log_group.migration.name
  })
}

# Use fargate container for queue
# module "run_migration" {
#   source            = "./modules/ecs_run_task"
#   cluster_name      = "ECS-Migration"
#   is_scheduled_task = false
#   tasks = [
#     {
#       container_definitions = data.template_file.db_migration.rendered
#       expression_start      = ""
#       name                  = "migration"
#     }
#   ]
#   execution_role_arn = module.iam_ecs.execution_role_arn
#   task_role_arn      = module.iam_ecs.task_role_arn
#   cpu                = var.queue_cpu
#   memory             = var.queue_memory
#   security_group_ids = [module.sg.ecs.id]
#   subnet_ids         = module.vpc.private_subnet_ids
#   is_public_subnet   = false
#   desired_count      = 0
#   min_capacity       = 0
#   max_capacity       = 0
# }

module "local_exec_migration" {
  source                = "./modules/ecs_one_off_task"
  name                  = "ECS-Migration"
  ecs_cluster_name      = module.ecs_fargate.cluster_name
  container_definitions = data.template_file.db_migration.rendered
  execution_role_arn    = module.iam_ecs.execution_role_arn
  task_role_arn         = module.iam_ecs.task_role_arn
  cpu                   = var.task_cpu
  memory                = var.task_memory
  security_group_ids    = [module.sg.ecs.id]
  subnet_ids            = module.vpc.public_subnet_ids
  profile               = var.aws.config.profile
  region                = var.aws.credentials.region
}
