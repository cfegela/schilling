# Virtual Private Gateway — AWS side of the VPN tunnel
resource "aws_vpn_gateway" "main" {
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${var.project_name}-vgw" })
}

# Customer Gateway — represents the on-premise router/firewall
resource "aws_customer_gateway" "main" {
  bgp_asn    = var.onprem_bgp_asn
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"
  tags       = merge(var.tags, { Name = "${var.project_name}-cgw" })
}

# Site-to-Site VPN Connection (dynamic routing via BGP)
# If the on-premise device does not support BGP, set static_routes_only = true
# and add aws_vpn_connection_route resources for each on-premise CIDR.
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = false

  tags = merge(var.tags, { Name = "${var.project_name}-vpn" })
}

# Propagate VPN routes into private route tables so ECS/Aurora can reach on-premise
resource "aws_vpn_gateway_route_propagation" "private" {
  count          = length(var.private_route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = var.private_route_table_ids[count.index]
}
