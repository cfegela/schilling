variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "onprem_public_ip" {
  description = "Public IP of the on-premise router/firewall"
  type        = string
}

variable "onprem_bgp_asn" {
  description = "BGP ASN of the on-premise customer gateway device"
  type        = number
  default     = 65000
}

variable "private_route_table_ids" {
  description = "Private route table IDs to enable VPN route propagation"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
