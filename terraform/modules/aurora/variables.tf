variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the Aurora subnet group (should span >= 2 AZs)"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks — granted DB access"
  type        = string
}

variable "rotation_lambda_sg_id" {
  description = "Security group ID of the Secrets Manager rotation Lambda — granted DB access on port 5432"
  type        = string
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "engine" {
  description = "Aurora engine (aurora-postgresql or aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  type    = string
  default = "15.4"
}

variable "min_capacity" {
  description = "Aurora Serverless v2 minimum ACUs (0.5 allows scale-to-zero on pause)"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Aurora Serverless v2 maximum ACUs"
  type        = number
  default     = 16
}

variable "instance_count" {
  description = "Number of Aurora cluster instances (>= 2 for Multi-AZ HA)"
  type        = number
  default     = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
