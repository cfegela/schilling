variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the rotation Lambda (needs NAT Gateway access)"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region — used to build the Secrets Manager endpoint URL for the rotation Lambda"
  type        = string
}

variable "rotation_days" {
  description = "Automatically rotate DB credentials every N days"
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
