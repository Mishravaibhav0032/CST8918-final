# Discover a supported AKS version (no previews)
data "azurerm_kubernetes_service_versions" "cc" {
  location        = var.location
  include_preview = false
}

# 1) Network (RG + VNet + Subnets)
module "network" {
  source    = "../../modules/network"
  group_num = var.group_num
  location  = var.location
  tags      = var.tags
}

# 2) AKS (test) on the 'test' subnet
module "aks_test" {
  source       = "../../modules/aks"
  rg_name      = module.network.rg_name
  location     = var.location
  cluster_name = "aks-test-${var.group_num}"
  k8s_version  = data.azurerm_kubernetes_service_versions.cc.latest_version
  node_min     = 1
  node_max     = 1
  vm_size      = "Standard_B2s"
  subnet_id    = module.network.subnet_ids["admin"]
  tags         = var.tags
}

/* # 3) App (ACR + Redis + K8s)
module "app_test" {
  source    = "../../modules/app"
  providers = { kubernetes = kubernetes.test }

  rg_name  = module.network.rg_name
  location = var.location

  # ACR must be lowercase letters/digits only; sanitize and cap at 50 chars
  acr_name = substr(join("", regexall("[0-9a-z]", lower("acr-${var.group_num}"))), 0, 50)

  redis_name         = "redis-test-${var.group_num}"
  redis_sku_name     = "Basic"
  redis_sku_family   = "C"
  redis_sku_capacity = 0
  k8s_namespace      = "weather"
  # use a public image so the app comes up even before you push to ACR
  image              = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
  tags               = var.tags

  # Only wait for AKS (Kubernetes provider needs it)
  depends_on = [module.aks_test]
}

# 4) Give AKS kubelet identity permission to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.app_test.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_test.kubelet_object_id
  depends_on           = [module.aks_test, module.app_test]
}*/
