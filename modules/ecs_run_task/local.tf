locals {
  tasks = var.is_scheduled_task == true ? var.scheduled_tasks : var.tasks
}
