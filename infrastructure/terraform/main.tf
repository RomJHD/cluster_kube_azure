resource "time_sleep" "wait_10_seconds"{
    create_duration = "10s"
}

module "virtual_networks" {
    source                      = "./modules/network"
    vm_count                    = var.vm_count
    location                    = var.location
    region                      = var.region
    environment                 = var.environment
    rg_name                     = var.rg_name
    default_tags                = var.default_tags
    vnet_address_space          = var.vnet_address_space
    gateway_snet_subnet_address_space = var.gateway_snet_subnet_address_space
    dns_subnet_address_space    = var.dns_subnet_address_space
    azb_subnet_address_space    = var.azb_subnet_address_space
    apps1_subnet_address_space  = var.apps1_subnet_address_space
    apps2_subnet_address_space  = var.apps2_subnet_address_space
    depends_on                  = [ time_sleep.wait_10_seconds ]
    address_prefix_master       = var.address_prefix_master
    address_prefix_worker1      = var.address_prefix_worker1
    address_prefix_worker2      = var.address_prefix_worker2

}

module "vm" {
  source                        = "./modules/vm"
  vm_count                      = var.vm_count
  location                      = var.location
  environment                   = var.environment
  rg_name                       = var.rg_name
  default_tags                  = var.default_tags
  sa1-boot-diagnostics_uri      = module.storage_accounts.sa1-boot-diagnostics-uri
  kube_nics_id                  = module.virtual_networks.kube_nics_id
  depends_on                    = [module.virtual_networks, module.storage_accounts, time_sleep.wait_10_seconds]
}

module "traffic_rules" {
  source                        = "./modules/traffic_rules"
  location                      = var.location
  environment                   = var.environment
  rg_name                       = var.rg_name
  subnet_with_pip_id            = module.virtual_networks.subnet_with_pip_id
  default_tags                  = var.default_tags
  depends_on                    = [ module.vm, time_sleep.wait_10_seconds ]
}

module "storage_accounts" {
  source                        = "./modules/storage_accounts"
  location                      = var.location
  environment                   = var.environment
  rg_name                       = var.rg_name
  default_tags                  = var.default_tags
  depends_on                    = [ var.rg_name, time_sleep.wait_10_seconds ]
}