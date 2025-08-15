terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

variable "group_num" { type = string }
variable "tags"      { type = map(string) }
variable "location" {
  type    = string
  default = "canadacentral"
}

resource "azurerm_resource_group" "rg" {
  name     = "cst8918-final-project-group-${var.group_num}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cst8918-${var.group_num}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/14"]
  tags                = var.tags
}

locals {
  subnets = {
    prod  = "10.0.0.0/16"
    test  = "10.1.0.0/16"
    dev   = "10.2.0.0/16"
    admin = "10.3.0.0/16"
  }
}

resource "azurerm_subnet" "subnets" {
  for_each             = local.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

output "rg_name" { value = azurerm_resource_group.rg.name }
output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "subnet_ids" {
  value = { for k, s in azurerm_subnet.subnets : k => s.id }
}
