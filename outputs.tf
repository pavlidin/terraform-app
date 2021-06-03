output "public_ip_address" {
  value = tostring(data.azurerm_public_ip.app.*.ip_address)
}