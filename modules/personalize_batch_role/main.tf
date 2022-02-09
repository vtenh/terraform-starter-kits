# ecs_task_assume_role allow ecs-tasks.amazonaws.com to act on our behalf
resource "aws_iam_role" "personalize_assume_role" {
  name               = "${var.name}"
  assume_role_policy = file("${path.module}/template/personalize_role.json")
  # file("./policies/ecs_task_assume_role.json")
}

# gives ecs_task_assume_role with the following permission
resource "aws_iam_role_policy" "personalize_policy" {
  name   = "personalize_policy"
  role   = aws_iam_role.personalize_assume_role.id
  policy = file("${path.module}/template/role_policy.json")
}
