############
# This module is used to run scheduled task
# Scheduled task: we don't need the aws_ecs_service resource, min_capacity, max capacity and desired_count
############
resource "aws_iam_role" "main" {
  name               = var.cluster_name
  assume_role_policy = file("${path.module}/template/role.json")
}

resource "aws_iam_role_policy" "main" {
  name   = var.cluster_name
  role   = aws_iam_role.main.id
  policy = file("${path.module}/template/policy.json")
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "main" {
  count                    = length(local.tasks)
  family                   = local.tasks[count.index].name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = local.tasks[count.index].container_definitions
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
}

########
# Use aws_cloudwatch_event_rule below instead
# Cloudwatch event rule does not required when to stop
########

# resource "aws_ecs_service" "main" {
#   count           = var.is_scheduled_task == true ? 0 : 1

#   name            = local.tasks[count.index].name
#   cluster         = aws_ecs_cluster.main.id
#   launch_type     = "FARGATE"
#   task_definition = aws_ecs_task_definition.main[count.index].arn

#   desired_count = var.desired_count

#   network_configuration {
#     security_groups  = var.security_group_ids
#     subnets          = var.subnet_ids
#     assign_public_ip = var.is_public_subnet # for public subnet public ip must be true
#   }
# }

# resource "aws_appautoscaling_target" "main" {
#   count             = length(local.tasks)
#   service_namespace = "ecs"

#   resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main[count.index].name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   max_capacity       = var.max_capacity
#   # scheduled task min capacity can be 0 but queue it must always run
#   min_capacity = var.min_capacity
# }


# resource "aws_appautoscaling_scheduled_action" "start_task" {
#   # this resource get created only in case of scheduled task.
#   count = var.is_scheduled_task == true ? length(local.tasks) : 0

#   name               = "${local.tasks[count.index].name}-task-start"
#   service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
#   resource_id        = aws_appautoscaling_target.main[count.index].resource_id
#   scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension

#   # At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields).
#   # In UTC. https://docs.aws.amazon.com/autoscaling/application/APIReference/Welcome.html
#   schedule = local.tasks[count.index].expression_start

#   # set min and max capacity to 1 to make service run task again
#   scalable_target_action {
#     min_capacity = var.min_capacity
#     max_capacity = var.max_capacity
#   }
# }

# # After running it exits, thus no need to schedule to stop the task
# resource "aws_appautoscaling_scheduled_action" "stop_task" {
#   # this resource get created only in case of scheduled task.
#   count              = length(local.tasks)
#   name               = "${local.tasks[count.index].name}-task-stop"
#   service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
#   resource_id        = aws_appautoscaling_target.main[count.index].resource_id
#   scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension

#   # At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields).
#   # In UTC. https://docs.aws.amazon.com/autoscaling/application/APIReference/Welcome.html
#   # might need to add expression_stop back to tasks
#   schedule = local.tasks[count.index].expression_stop

#   # set min and max to cero to make the service stop the task
#   scalable_target_action {
#     min_capacity = 0
#     max_capacity = 0
#   }
# }

#####
# Cloudwatch event rule and target is the defacto scheduled task by AWS.
# However I could not find a way to stop the task.
# As you can see this rule is not related to service
# Running task this way is not seen in AWS management console
#####

resource "aws_cloudwatch_event_rule" "main" {
  # this resource get created only in case of scheduled task.

  count = var.is_scheduled_task == true ? length(local.tasks) : 0

  name = "${local.tasks[count.index].name}-rule"
  # CloudWatch Events supports Cron Expressions and Rate Expressions
  # For example, "cron(0 20 * * ? *)" or "rate(5 minutes)".
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
  schedule_expression = local.tasks[count.index].expression_start
}

resource "aws_cloudwatch_event_target" "main" {
  # this resource get created only in case of scheduled task.

  count = var.is_scheduled_task == true ? length(local.tasks) : 0

  rule = aws_cloudwatch_event_rule.main[count.index].id
  arn  = aws_ecs_cluster.main.arn

  target_id = "${local.tasks[count.index].name}_scheduleed_task"
  role_arn  = aws_iam_role.main.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.main[count.index].arn
    task_count          = 1
    launch_type         = "FARGATE"

    network_configuration {
      security_groups  = var.security_group_ids
      subnets          = var.subnet_ids
      assign_public_ip = var.is_public_subnet
    }
  }
}
