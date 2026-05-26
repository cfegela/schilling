# ── Route 53 Hosted Zone ────────────────────────────────────────────────────────

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform — ${var.project_name}"
  tags    = var.tags
}
