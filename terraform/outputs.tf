output "cloudfront_domain_name" {
  description = "CloudFront distribution domain — primary public entry point"
  value       = module.frontend.cloudfront_domain_name
}

output "alb_dns_name" {
  description = "ALB DNS name (CloudFront API origin)"
  value       = module.ecs.alb_dns_name
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.aurora.cluster_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora.cluster_reader_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpn_connection_id" {
  description = "Site-to-Site VPN connection ID"
  value       = module.vpn.vpn_connection_id
}

output "vpn_customer_gateway_configuration" {
  description = "XML config to apply to the on-premise customer gateway device"
  value       = module.vpn.customer_gateway_configuration
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URI — use as the base image path in ECS task definitions"
  value       = module.ecr.repository_url
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "NS records to configure at your domain registrar"
  value       = module.route53.name_servers
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate — set this on CloudFront or ALB HTTPS listeners"
  value       = module.acm.certificate_arn
}

output "db_secret_arn" {
  description = "ARN of the DB credentials secret — reference this in ECS task definitions to inject credentials"
  value       = module.secrets.db_secret_arn
}
