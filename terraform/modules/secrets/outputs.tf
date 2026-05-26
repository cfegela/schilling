output "db_password" {
  description = "Initial DB password — Secrets Manager rotates this automatically after first apply"
  value       = random_password.db.result
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_id" {
  description = "ID of the DB credentials secret (used to attach the secret version)"
  value       = aws_secretsmanager_secret.db.id
}

output "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda — passed to aws_secretsmanager_secret_rotation"
  value       = aws_serverlessapplicationrepository_cloudformation_stack.rotation.outputs["RotationLambdaARN"]
}

output "rotation_lambda_sg_id" {
  description = "Security group ID of the rotation Lambda — allow ingress from this SG to Aurora on port 5432"
  value       = aws_security_group.rotation_lambda.id
}
