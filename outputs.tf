output "public_ip_address" {
  value = formatlist("%s", data.azurerm_public_ip.app.*.ip_address)
}