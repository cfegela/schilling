output "repository_url" {
  description = "Full URI of the ECR repository (registry/repo)"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.main.arn
}

output "registry_id" {
  description = "AWS account ID that owns the registry"
  value       = aws_ecr_repository.main.registry_id
}
