terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.14"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
#   skip_provider_registration = true
  resource_provider_registrations = "none"
}