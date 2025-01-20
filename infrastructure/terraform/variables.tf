variable subscription_id {}
variable region {}
variable location {}
variable rg_name {}
variable environment {}
variable "vm_count" {}
variable "pub_key"{}

variable "default_tags" {
  type = map(string)
  default = {
    "product-id"           = "P00001"
    "business-unit"        = "capgemini"
    "environment"          = "dev"
    "application-id"       = "A00001"
    "maintainer-apps"      = "rjacek"
    "maintainer-infra"     = "rjacek"
    "business-impact"      = "critical"
    "operation-management" = "rjacek"
  }
}

variable vnet_address_space {}
variable gateway_snet_subnet_address_space {}
variable dns_subnet_address_space {}
variable azb_subnet_address_space {}
variable apps1_subnet_address_space {}
variable apps2_subnet_address_space {}
variable azb_scl_units {}
variable fw_allocation_method {}
variable fw_sku {}
variable address_prefix_master {}
variable address_prefix_worker1 {}
variable address_prefix_worker2 {}