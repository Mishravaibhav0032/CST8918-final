provider "azurerm" {
  features {}
}

# --- TEMPORARILY DISABLED (re-enable in Phase 2) ---
# provider "kubernetes" {
#   alias                  = "test"
#   host                   = module.aks_test.host
#   client_certificate     = base64decode(module.aks_test.client_certificate)
#   client_key             = base64decode(module.aks_test.client_key)
#   cluster_ca_certificate = base64decode(module.aks_test.cluster_ca)
# }
