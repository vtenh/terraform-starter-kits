output "cluster_id" {
  value = aws_ecs_cluster.main.id
}
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.main.name
}

output "service_resource_id" {
  value = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
}
