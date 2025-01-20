resource "azurerm_storage_account" "sa1-boot-diagnostics" {
  name                     = "sa1bootdiagnostics"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = var.default_tags
}

#Useless if used on Cloud Guru sandboxes => boring to use the cloud tfstate.

# resource "azurerm_storage_account" "sa2-tfbackend-storage" {
#   name                     = "tfstatekuberj"
#   resource_group_name      = var.rg_name
#   location                 = var.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   allow_nested_items_to_be_public = false
#   tags = var.default_tags
# }

# resource "azurerm_storage_container" "tfstate-container" {
#   name                  = "tfstate-container"
#   storage_account_id  = azurerm_storage_account.sa2-tfbackend-storage.id
#   container_access_type = "private"
# }