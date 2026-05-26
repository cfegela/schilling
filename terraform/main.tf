locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  tags         = local.common_tags
}

module "vpn" {
  source                  = "./modules/vpn"
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  onprem_public_ip        = var.onprem_public_ip
  onprem_bgp_asn          = var.onprem_bgp_asn
  private_route_table_ids = module.vpc.private_route_table_ids
  tags                    = local.common_tags
}

module "secrets" {
  source             = "./modules/secrets"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = var.aws_region
  tags               = local.common_tags
}

module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = local.common_tags
}

# Allow ECS tasks to fetch the DB secret at container startup
resource "aws_iam_role_policy" "ecs_read_db_secret" {
  name = "${var.project_name}-ecs-read-db-secret"
  role = module.ecs.task_execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [module.secrets.db_secret_arn]
    }]
  })
}

module "aurora" {
  source                 = "./modules/aurora"
  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_id  = module.ecs.ecs_security_group_id
  rotation_lambda_sg_id  = module.secrets.rotation_lambda_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = module.secrets.db_password
  tags                   = local.common_tags
}

# Full secret version — written after Aurora is up so the host endpoint is available.
# The rotation Lambda reads this JSON to connect and rotate credentials.
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = module.secrets.db_secret_id
  secret_string = jsonencode({
    username = var.db_username
    password = module.secrets.db_password
    engine   = "aurora-postgresql"
    host     = module.aurora.cluster_endpoint
    port     = 5432
    dbname   = var.db_name
  })
}

resource "aws_secretsmanager_secret_rotation" "db" {
  secret_id           = module.secrets.db_secret_id
  rotation_lambda_arn = module.secrets.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_secretsmanager_secret_version.db]
}

module "frontend" {
  source       = "./modules/frontend"
  project_name = var.project_name
  alb_dns_name = module.ecs.alb_dns_name
  tags         = local.common_tags
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  tags         = local.common_tags
}

module "route53" {
  source       = "./modules/route53"
  project_name = var.project_name
  domain_name  = var.domain_name
  tags         = local.common_tags
}

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  zone_id     = module.route53.zone_id
  tags        = local.common_tags
}
