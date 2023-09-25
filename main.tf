terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = ">=2.4.1"
    }
  }
}

provider "azurerm" {
    features {
      key_vault {
        purge_soft_delete_on_destroy = true
      }
    }
  
}
data "azurerm_client_config" "current" {}
resource "azurerm_resource_group" "rg" {
  name = "devops-app"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name = "devopsvnet"
  address_space = [ "10.0.0.0/16" ]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sn" {
  name = "VM"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.1.0/24" ]
}

resource "azurerm_storage_account" "devopssa" {
  name = "devopssa"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "devopsenv"
  }
}

resource "azurerm_network_interface" "vmnic" {
  name = "devopsnic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "devopsvm" {
  name = "devopsvm"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [ azurerm_network_interface.vmnic.id ]
  vm_size = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2016-Datacenter-Server-Core-smalldisk"
    version = "latest"
  }
  storage_os_disk {
    name = "devopsos"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = "devopsvm"
    admin_username = "devops"
    admin_password = "Facebook@0911"
  }
  os_profile_windows_config {
  }
}