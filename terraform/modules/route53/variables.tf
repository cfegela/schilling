variable "project_name" {
  type = string
}

variable "domain_name" {
  description = "Apex domain to host (e.g. example.com)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
