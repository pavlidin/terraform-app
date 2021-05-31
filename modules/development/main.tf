resource "azurerm_resource_group" "app" {
  name     = "app"
  location = var.location

  tags = {
    environment = "App Dev Infrastructure"
  }
}