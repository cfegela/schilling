variable "project_name" {
  type = string
}

variable "alb_dns_name" {
  description = "ALB DNS name used as the CloudFront API origin"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
