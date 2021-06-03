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
  name                = "${var.prefix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name

  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet" "appsubnet" {
  name                 = "${var.prefix}-Subnet"
  resource_group_name  = azurerm_resource_group.java_app.name
  virtual_network_name = azurerm_virtual_network.appnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "apppublicip" {
  name                = "${var.prefix}-PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name
  allocation_method   = "Dynamic"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "${var.prefix}-NetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_network_interface" "appnic" {
  name                = "${var.prefix}-NIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apppublicip.id
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_account" "appstorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.java_app.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}