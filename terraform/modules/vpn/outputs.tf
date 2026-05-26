output "vpn_connection_id" {
  description = "Site-to-Site VPN connection ID"
  value       = aws_vpn_connection.main.id
}

output "vpn_gateway_id" {
  description = "Virtual Private Gateway ID"
  value       = aws_vpn_gateway.main.id
}

output "customer_gateway_id" {
  description = "Customer Gateway ID"
  value       = aws_customer_gateway.main.id
}

output "customer_gateway_configuration" {
  description = "XML configuration to apply to the on-premise customer gateway device"
  value       = aws_vpn_connection.main.customer_gateway_configuration
  sensitive   = true
}
