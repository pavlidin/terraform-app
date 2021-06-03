terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "pf6-devops-team3"
    workspaces {
      prefix = "terraform-app-"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "java_app" {
  name     = var.resource_group
  location = var.location

  tags = {
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "appnetwork" {
  name                = "app-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name

  tags = {
    environment = var.environment
  }
}