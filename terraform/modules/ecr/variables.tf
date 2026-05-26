variable "project_name" {
  description = "Project name — used as the ECR repository name"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
