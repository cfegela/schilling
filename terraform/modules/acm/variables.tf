variable "domain_name" {
  description = "Apex domain for the certificate (e.g. example.com). A wildcard SAN (*.example.com) is included automatically."
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID used to create DNS validation records"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
