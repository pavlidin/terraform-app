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
  count = "${var.counter}"
  name                 = "${var.prefix}-Subnet"
  resource_group_name  = azurerm_resource_group.java_app.name
  virtual_network_name = azurerm_virtual_network.appnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "apppublicip" {
  count = "${var.counter}"
  name                = "${var.prefix}-PublicIP-${format("%d", count.index + 1)}"
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
  count = "${var.counter}"
  name                = "${var.prefix}-NIC-${format("%d", count.index + 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.java_app.name

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration-${format("%d", count.index + 1)}"
    subnet_id                     = azurerm_subnet.appsubnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.apppublicip[count.index].id}"
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_network_interface_security_group_association" "appsga" {
  count = length(azurerm_network_interface.appnic)
  network_interface_id      = "${azurerm_network_interface.appnic[count.index].id}"
  network_security_group_id = azurerm_network_security_group.appnsg.id
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.java_app.name
  }
  byte_length = 8
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

# VMs
resource "azurerm_linux_virtual_machine" "appvm" {
  count = "${var.counter}"
  name                  = "${var.prefix}-VM-${format("%d", count.index + 1)}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.java_app.name
  network_interface_ids = ["${azurerm_network_interface.appnic[count.index].id}"]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.prefix}-Disk-${format("%d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  computer_name                   = "${var.prefix}-VM-${format("%d", count.index + 1)}"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.public_key
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.appstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_ssh_public_key" "javaAppSSHKey" {
  name                = "${var.prefix}-SSHKey"
  resource_group_name = azurerm_resource_group.java_app.name
  location            = var.location
  public_key          = var.public_key
}

data "azurerm_public_ip" "app" {
  count = var.counter
  name                = azurerm_public_ip.apppublicip.name
  resource_group_name = azurerm_linux_virtual_machine.appvm[count.index].resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.appvm[count.index]]
}