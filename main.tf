provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test-vm-rg" {
  name     = "testvmrg"
  location = "UK South"
}
########################################
# Data Block
########################################
data "azurerm_subnet" "example" {
  name                 = "default"
  virtual_network_name = "Core_VNET"
  resource_group_name  = "Core_Infrastructure"
}
output "subnet_id" {
  value = data.azurerm_subnet.example.id
}
##########################################

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.test-vm-rg.location
  resource_group_name = azurerm_resource_group.test-vm-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.test-vm-rg.name
  location            = azurerm_resource_group.test-vm-rg.location
  size                = "Standard_B2s"
  # provide  custome image id . This can be obtanined from image properties in Azure portal
  source_image_id    = "/subscriptions/xxxx-xxxx-xxxx-xxxx-/resourceGroups/vmforiamge/providers/Microsoft.Compute/galleries/bazcomputegallery/images/Gold-Gallery-Image"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!" 
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  } 
}

resource "azurerm_virtual_machine_extension" "domain_join" {
   name                       = azurerm_windows_virtual_machine.example.name
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "baz.corp",
      "OUPath": "",  
      "User": "user@domain.co.uk",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "password for the user"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
  
}

# OU path in teh sction above has no input so the VMs go in to the default OU. sample user name and password to be updated with the live details.

