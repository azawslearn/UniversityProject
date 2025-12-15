resource "azurerm_resource_group" "hybrid_rg" {
  name     = "hybrid-rg"
  location = var.location
}

resource "azurerm_virtual_network" "hybrid_vnet" {
  name                = "hybrid-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name

  dns_servers = ["10.0.5.5"]
}

resource "azurerm_subnet" "hybrid_subnet" {
  name                 = "hybrid-subnet"
  resource_group_name  = azurerm_resource_group.hybrid_rg.name
  virtual_network_name = azurerm_virtual_network.hybrid_vnet.name
  address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_network_security_group" "hybrid_nsg" {
  name                = "hybrid-nsg"
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name

  # Allow all inbound traffic
  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic
  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "hybrid_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hybrid_subnet.id
  network_security_group_id = azurerm_network_security_group.hybrid_nsg.id
}

####################
## DC ###
#######################

resource "azurerm_public_ip" "hybrid_pip" {
  name                = "hybrid-pip"
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "hybrid_nic" {
  name                = "hybrid-nic"
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hybrid_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.5.5"
    public_ip_address_id          = azurerm_public_ip.hybrid_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "hybrid_dc" {
  name                = "hybrid-dc"
  resource_group_name = azurerm_resource_group.hybrid_rg.name
  location            = azurerm_resource_group.hybrid_rg.location
  size                = var.dc_size
  admin_username      = "azureuser"
  admin_password      = var.dc_password
  network_interface_ids = [
    azurerm_network_interface.hybrid_nic.id,
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

  provision_vm_agent       = true

}



resource "azurerm_virtual_machine_extension" "hybrid_dc_extension" {
  name                       = "DC-ext"
  virtual_machine_id         = azurerm_windows_virtual_machine.hybrid_dc.id
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
  create_duration = "350s"
  depends_on      = [azurerm_virtual_machine_extension.hybrid_dc_extension]
}

######################################
######## EXCHANGE SERVER 2019 ########
######################################

resource "azurerm_public_ip" "ex2019_pip" {
  name                = "hybrid-exchange-pip"
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "ex2019_nic" {
  depends_on          = [azurerm_network_interface.hybrid_nic]
  name                = "hybrid-exchange-nic"
  location            = azurerm_resource_group.hybrid_rg.location
  resource_group_name = azurerm_resource_group.hybrid_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hybrid_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.5.15"
    public_ip_address_id          = azurerm_public_ip.ex2019_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "ex2019" {
  name                = "ex2019"
  resource_group_name = azurerm_resource_group.hybrid_rg.name
  location            = azurerm_resource_group.hybrid_rg.location
  size                = var.exchange_size
  admin_username      = "exazureuser"
  admin_password      = var.dc_password
  depends_on          = [time_sleep.wait_for_ad]
  network_interface_ids = [
    azurerm_network_interface.ex2019_nic.id,
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

  provision_vm_agent       = true
}

resource "azurerm_virtual_machine_extension" "hybrid_ex_extension" {
  name                       = "ex2019-ext"
  virtual_machine_id         = azurerm_windows_virtual_machine.ex2019.id
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



resource "azurerm_virtual_machine_extension" "ex2019_domjoin" {
  name                 = "domjoin-exchange"
  virtual_machine_id   = azurerm_windows_virtual_machine.ex2019.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  depends_on = [
    time_sleep.wait_for_ad,
    azurerm_virtual_machine_extension.hybrid_ex_extension
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

















