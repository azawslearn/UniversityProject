resource "azurerm_public_ip" "uniProject_pip" {
  name                = "uniProject-pip"
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "uniProject_nic" {
  name                = "uniProject-nic"
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.uniProject_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.5.5"
    public_ip_address_id          = azurerm_public_ip.uniProject_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "uniProject_dc" {
  name                = "uniProject-dc"
  resource_group_name = azurerm_resource_group.uniProject_rg.name
  location            = azurerm_resource_group.uniProject_rg.location
  size                = var.dc_size
  admin_username      = "azureuser"
  admin_password      = var.dc_password
  network_interface_ids = [
    azurerm_network_interface.uniProject_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  provision_vm_agent = true
}



resource "azurerm_virtual_machine_extension" "uniProject_dc_extension" {
  name                       = "DC-ext"
  virtual_machine_id         = azurerm_windows_virtual_machine.uniProject_dc.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.dc_configure_template.rendered)}')) | Out-File -filepath 01-dc-install.ps1\" && powershell -ExecutionPolicy Unrestricted -File 01-dc-install.ps1"
  }
  SETTINGS
}

data "template_file" "dc_configure_template" {
  template = file("${path.module}/powershell/01-dc-install.ps1")
}


resource "time_sleep" "wait_for_ad" {
  create_duration = "300s"
  depends_on      = [azurerm_virtual_machine_extension.uniProject_dc_extension]
}

output "dc_ip" {
  description = "dc_ip"
  value       = azurerm_public_ip.uniProject_pip.ip_address
}


