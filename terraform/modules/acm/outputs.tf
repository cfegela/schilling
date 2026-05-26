output "certificate_arn" {
  description = "ARN of the validated ACM certificate — pass to CloudFront or ALB HTTPS listeners"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
