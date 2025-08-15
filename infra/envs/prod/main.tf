module "aks_prod" {
  source       = "../../modules/aks"
  rg_name      = module.network.rg_name
  location     = var.location
  cluster_name = "aks-prod-mish0032"
  k8s_version  = "1.32.0"
  node_min     = 1
  node_max     = 3
  vm_size      = "Standard_B2s"
  subnet_id    = module.network.subnet_ids["prod"]
  tags         = var.tags
}

provider "kubernetes" {
  alias                  = "prod"
  host                   = module.aks_prod.host
  client_certificate     = base64decode(module.aks_prod.client_certificate)
  client_key             = base64decode(module.aks_prod.client_key)
  cluster_ca_certificate = base64decode(module.aks_prod.cluster_ca)
}

module "app_prod" {
  source            = "../../modules/app"
  providers         = { kubernetes = kubernetes.prod }
  rg_name           = module.network.rg_name
  location          = var.location
  acr_name          = "acrprodmish0032"
  redis_name        = "redis-prod-${var.group_num}"
  redis_sku_name    = "Standard"
  redis_sku_family  = "C"
  redis_sku_capacity= 1
  k8s_namespace     = "weather"
  image             = "acrprod${var.group_num}.azurecr.io/weather:placeholder"
  tags              = var.tags
}

resource "azurerm_role_assignment" "acr_pull_prod" {
  scope                = module.app_prod.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_prod.kubelet_object_id
}
