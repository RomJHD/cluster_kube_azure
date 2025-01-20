# terraform {
#   backend "azurerm" {
#     resource_group_name = "1-f4ba7a5a-playground-sandbox"
#     storage_account_name = "tfstatekuberj"
#     container_name = "tfstate-container"
#     key = "terraform.tfstate"
#   }
# }