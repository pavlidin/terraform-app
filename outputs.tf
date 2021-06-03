output "public_ip_address" {
  value = tolist(data.azurerm_public_ip.app.*.ip_address)
}