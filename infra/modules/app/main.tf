terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# Providers are configured/passed from the root (including any kubernetes alias)

variable "rg_name" {
  type = string
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "acr_name" {
  type = string
}

variable "redis_name" {
  type = string
}

# test: Basic; prod: Standard
variable "redis_sku_name" {
  type    = string
  default = "Basic"
}

variable "redis_sku_family" {
  type    = string
  default = "C"
}

# Basic C0 / Standard C1, ...
variable "redis_sku_capacity" {
  type    = number
  default = 0
}

variable "k8s_namespace" {
  type    = string
  default = "weather"
}

# e.g., myacr.azurecr.io/weather:${tag}
variable "image" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_redis_cache" "redis" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.rg_name
  capacity            = var.redis_sku_capacity
  family              = var.redis_sku_family
  sku_name            = var.redis_sku_name
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"
  tags                = var.tags
  subnet_id = var.subnet_id != null ? var.subnet_id : null
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "weather"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels    = { app = "weather" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "weather" }
    }

    template {
      metadata {
        labels = { app = "weather" }
      }

      spec {
        container {
          name  = "weather"
          image = var.image

          port {
            container_port = 3000
          }

          env {
            name  = "REDIS_URL"
            value = "rediss://${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6380"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "svc" {
  metadata {
    name      = "weather-svc"
    namespace = kubernetes_namespace.ns.metadata[0].name
  }

  spec {
    selector = { app = "weather" }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

output "acr_name"       { value = azurerm_container_registry.acr.name }
output "redis_hostname" { value = azurerm_redis_cache.redis.hostname }
