output "vnet_id" {
    value = azurerm_virtual_network.vnet_kube.id
} 

output "subnet_with_pip_id"{
    value = azurerm_subnet.snet_apps1.id
}

output "kube_nics"{
    value = {for nic in azurerm_network_interface.kube_nic: nic.name => nic.id}
}

output "kube_nics_id"{
    value = [for nic in azurerm_network_interface.kube_nic: nic.id]
}

output "PublicIP" {
  value = join(", ", [for ip in azurerm_public_ip.kube_public_ip : "NAME: ${ip.id} IP: ${ip.ip_address}\n"])
}