resource "azurerm_virtual_network" "vnet_kube" {
  name                = "vnet-${(var.default_tags.business-unit)}-${(var.default_tags.product-id)}-${var.default_tags.environment}-${(var.region)}"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.vnet_address_space

  tags = merge(
    var.default_tags, {
      "environment" = var.environment
    }
  )
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_public_ip" "kube_public_ip" {
  count               =  var.vm_count  
  name                = "kube-PublicIP-${count.index}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
}

resource "azurerm_subnet" "snet_dns" {
  name                = "snet-${var.default_tags.business-unit}-${var.default_tags.product-id}-${var.default_tags.environment}-dns"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_kube.name
  address_prefixes     = var.dns_subnet_address_space
}

# resource "azurerm_subnet" "AzureBastionSubnet" {
#   name                = "AzureBastionSubnet"
#   resource_group_name  = var.rg_name
#   virtual_network_name = azurerm_virtual_network.vnet_kube.name
#   address_prefixes     = var.azb_subnet_address_space
# }

resource "azurerm_subnet" "snet_apps1" {
  name                = "snet-${var.default_tags.business-unit}-${var.default_tags.product-id}-${var.default_tags.environment}-apps1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_kube.name
  address_prefixes     = var.apps1_subnet_address_space
}

resource "azurerm_network_interface" "kube_nic" {
    count               =  var.vm_count
    name                = "nic-${(var.default_tags.business-unit)}-${(var.default_tags.product-id)}-${(var.default_tags.application-id)}-${var.default_tags.environment}-${(var.region)}-${count.index}"
    location            = var.location
    resource_group_name = var.rg_name
    ip_forwarding_enabled = true

    ip_configuration {
        name                          = "Dynamic"
        subnet_id                     = azurerm_subnet.snet_apps1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.kube_public_ip[count.index].id
    }
}


resource "azurerm_route_table" "calico" {
  name      = "calico-route-table"
  location = var.location
  resource_group_name = var.rg_name

  route {
    
    name = "Master"
    address_prefix = var.address_prefix_master
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.kube_nic[0].private_ip_address
  }

  route {
    
    name = "Worker1"
    address_prefix = var.address_prefix_worker1
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.kube_nic[1].private_ip_address
  }

  route {
    
    name = "Worker2"
    address_prefix = var.address_prefix_worker2
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.kube_nic[2].private_ip_address
  }

}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.snet_apps1.id
  route_table_id = azurerm_route_table.calico.id
}