# ── DB password (generated, never stored in state in plaintext after rotation) ───

resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ── Secrets Manager secret container ────────────────────────────────────────────

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}/db-credentials"
  description             = "Aurora PostgreSQL credentials — auto-rotated every ${var.rotation_days} days"
  recovery_window_in_days = 7
  tags                    = var.tags
}

# ── Security group for the rotation Lambda ───────────────────────────────────────
# Egress: Aurora port 5432 + HTTPS 443 to reach Secrets Manager via NAT Gateway

resource "aws_security_group" "rotation_lambda" {
  name        = "${var.project_name}-db-rotation-sg"
  description = "Outbound access for Secrets Manager rotation Lambda"
  vpc_id      = var.vpc_id

  egress {
    description = "Aurora PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Secrets Manager HTTPS via NAT Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-db-rotation-sg" })
}

# ── Rotation Lambda — AWS-managed SAR application (single-user PostgreSQL) ───────

resource "aws_serverlessapplicationrepository_cloudformation_stack" "rotation" {
  name             = "${var.project_name}-db-rotation"
  application_id   = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
  semantic_version = "1.1.367"
  capabilities     = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

  parameters = {
    functionName        = "${var.project_name}-db-rotation-fn"
    endpoint            = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    vpcSubnetIds        = join(",", var.private_subnet_ids)
    vpcSecurityGroupIds = aws_security_group.rotation_lambda.id
  }
}
