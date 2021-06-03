output "public_ip_address" {
  value = formatlist("%s", data.azurerm_public_ip.app.*.ip_address)
  description = "The public IP address(es) of the ${var.prefix} VM(s)."
}