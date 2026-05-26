output "alb_dns_name" {
  description = "ALB DNS name (CloudFront API origin)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route 53 alias records)"
  value       = aws_lb.main.zone_id
}

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_security_group_id" {
  description = "Security group ID of ECS tasks (used by Aurora to allow DB access)"
  value       = aws_security_group.ecs_tasks.id
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution IAM role — attach additional policies here (e.g. Secrets Manager)"
  value       = aws_iam_role.ecs_task_execution.name
}
