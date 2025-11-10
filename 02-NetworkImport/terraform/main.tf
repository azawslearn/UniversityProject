resource "azurerm_resource_group" "uniProject_rg" {
  name     = "uniProject-rg"
  location = var.location
}

resource "azurerm_virtual_network" "uniProject_vnet" {
  name                = "uniProject-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name

  dns_servers = ["10.0.5.5"]
}

resource "azurerm_subnet" "uniProject_subnet" {
  name                 = "uniProject-subnet"
  resource_group_name  = azurerm_resource_group.uniProject_rg.name
  virtual_network_name = azurerm_virtual_network.uniProject_vnet.name
  address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_network_security_group" "uniProject_nsg" {
  name                = "uniProject-nsg"
  location            = azurerm_resource_group.uniProject_rg.location
  resource_group_name = azurerm_resource_group.uniProject_rg.name

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

resource "azurerm_subnet_network_security_group_association" "uniProject_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.uniProject_subnet.id
  network_security_group_id = azurerm_network_security_group.uniProject_nsg.id
}

