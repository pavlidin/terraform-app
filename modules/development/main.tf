resource "azurerm_resource_group" "appdev" {
  name     = "app-dev2"
  location = var.location

  tags = {
    environment = "App Development Infrastructure"
  }
}