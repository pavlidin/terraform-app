resource "azurerm_resource_group" "appdev" {
  name     = "app-dev"
  location = var.location

  tags = {
    environment = var.environment
  }
}