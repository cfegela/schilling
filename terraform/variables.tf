variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "schilling"
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "onprem_public_ip" {
  description = "Public IP address of the on-premise customer gateway device"
  type        = string
}

variable "onprem_bgp_asn" {
  description = "BGP ASN of the on-premise customer gateway device"
  type        = number
  default     = 65000
}

variable "db_name" {
  description = "Name of the Aurora database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the Aurora database"
  type        = string
  default     = "dbadmin"
}

variable "domain_name" {
  description = "Apex domain name (e.g. example.com) used for the Route 53 hosted zone and ACM certificate"
  type        = string
}
