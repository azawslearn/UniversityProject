output "dc_ip" {
  description = "dc_ip"
  value       = azurerm_public_ip.hybrid_pip.ip_address
}

output "ex2019_ip" {
  description = "ex2019_ip"
  value       = azurerm_public_ip.ex2019_pip.ip_address
}
