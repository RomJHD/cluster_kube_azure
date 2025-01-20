resource "azurerm_network_security_group" "nsg-1-allowInbound-tcp" {
    name                        = "nsg-1-allowInbound-tcp"
    location                    = var.location
    resource_group_name         = var.rg_name

    security_rule {
        name                        = "Allow_Inbound_TCP"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

    security_rule {
        name                        = "Allow_Inbound_443"
        priority                    = 101
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "443"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

    tags = var.default_tags

}

resource "azurerm_subnet_network_security_group_association" "kube_nsg_ass" {
  subnet_id = var.subnet_with_pip_id
  network_security_group_id = azurerm_network_security_group.nsg-1-allowInbound-tcp.id
}

