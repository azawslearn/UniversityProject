output "public_ip" {
  description = "Public IP of the Ubuntu VM"
  value       = azurerm_public_ip.pip.ip_address
}