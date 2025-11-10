######################################
######## EXCHANGE SERVER 2016 ########
######################################

resource "azurerm_public_ip" "ex2016_pip" {
  name                = "uniProject-client-pip"
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "ex2016_nic" {
  depends_on          = [azurerm_network_interface.uniProject_nic]
  name                = "uniProject-client-nic"
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.uniProject_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.5.15"
    public_ip_address_id          = azurerm_public_ip.ex2016_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "ex2016" {
  name                = "ex2016"
  resource_group_name = azurerm_resource_group.uniProject_rg.name
  location            = azurerm_resource_group.uniProject_rg.location
  size                = var.client_size
  admin_username      = "exazureuser"
  admin_password      = var.dc_password
  depends_on          = [time_sleep.wait_for_ad]
  network_interface_ids = [
    azurerm_network_interface.ex2016_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  provision_vm_agent = true
}

resource "azurerm_virtual_machine_extension" "uniProject_ex_extension" {
  name                       = "ex2016-ext"
  virtual_machine_id         = azurerm_windows_virtual_machine.ex2016.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ex_configure_template.rendered)}')) | Out-File -filepath 01-ex-servers.ps1\" && powershell -ExecutionPolicy Unrestricted -File 01-ex-servers.ps1"
  }
  SETTINGS
}

data "template_file" "ex_configure_template" {
  template = file("${path.module}/powershell/01-ex-servers.ps1")
}



resource "azurerm_virtual_machine_extension" "ex2016_domjoin" {
  name                 = "domjoin-client"
  virtual_machine_id   = azurerm_windows_virtual_machine.ex2016.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  depends_on = [
    time_sleep.wait_for_ad,
    azurerm_virtual_machine_extension.uniProject_ex_extension
  ]


  settings = <<SETTINGS
  {
    "Name": "uniproject.local",
    "OUPath": "",
    "User": "ad\\azureuser",
    "Restart": "true",
    "Options": "3"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "Password": "${var.dc_password_new}"
  }
  PROTECTED_SETTINGS
}




output "ex2016_ip" {
  description = "ex2016_ip"
  value       = azurerm_public_ip.ex2016_pip.ip_address
}
