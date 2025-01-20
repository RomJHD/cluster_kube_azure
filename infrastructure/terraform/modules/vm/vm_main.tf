resource "azurerm_linux_virtual_machine" "kube_vm" {
    # module.vm.azurerm_linux_virtual_machine.kube_vm[2]

    count                               =  var.vm_count
    name                                = "${var.default_tags.environment}-${var.default_tags.product-id}${var.default_tags.application-id}-${count.index}"
    location                            = var.location
    resource_group_name                 = var.rg_name
    network_interface_ids               = [var.kube_nics_id[count.index]]
    disable_password_authentication     = true
    size                                = "Standard_D2s_v3"
    admin_username                      = "azureadm"

    admin_ssh_key {
        username   = "azureadm"
        public_key = file(var.pub_key)
    }

    boot_diagnostics {
        storage_account_uri = var.sa1-boot-diagnostics_uri
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
    }
    os_disk {
        name                    = "${var.default_tags.environment}-disk-${var.default_tags.product-id}${var.default_tags.application-id}-${count.index}"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    tags = merge(
    var.default_tags,
    {
      "virtualmachine-type" = count.index == 0 ? "master" : "worker"
    }
    )
}