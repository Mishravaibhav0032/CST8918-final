terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# ── Variables ──────────────────────────────────────────────────────────────────
variable "rg_name" {
  type = string
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "cluster_name" {
  type = string
}

variable "k8s_version" {
  type = string
}

variable "node_min" {
  type    = number
  default = 1
  validation {
    condition     = var.node_min >= 1
    error_message = "node_min must be >= 1."
  }
}

variable "node_max" {
  type    = number
  default = 1
  validation {
    condition     = var.node_max >= var.node_min
    error_message = "node_max must be >= node_min."
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Networking (choose values that DO NOT overlap your VNet)
variable "service_cidr" {
  description = "Kubernetes service CIDR; must not overlap with the VNet address space."
  type        = string
  # Safe default if your VNet is 10.0.0.0/16
  default     = "10.240.0.0/16"
}

variable "dns_service_ip" {
  description = "IP for kube-dns within the service CIDR."
  type        = string
  default     = "10.240.0.10"
}

variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR; must not overlap with the VNet or service CIDR."
  type        = string
  default     = "172.17.0.1/16"
}

# ── Locals ─────────────────────────────────────────────────────────────────────
locals {
  autoscale = var.node_max > var.node_min
}

# ── AKS Cluster ────────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = "${var.cluster_name}-dns"

  kubernetes_version = var.k8s_version

  default_node_pool {
    name                = "system"
    vm_size             = var.vm_size

    # Correct handling for autoscale vs fixed-size pools:
    enable_auto_scaling = local.autoscale
    min_count           = local.autoscale ? var.node_min : null
    max_count           = local.autoscale ? var.node_max : null
    node_count          = local.autoscale ? null : var.node_min

    vnet_subnet_id               = var.subnet_id
    type                         = "VirtualMachineScaleSets"
    os_disk_size_gb              = 64
    only_critical_addons_enabled = true
    node_labels                  = { pool = "system" }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    # Azure CNI
    network_plugin      = "azure"
    network_policy      = "azure"
    load_balancer_sku   = "standard"

    # ✅ Non-overlapping CIDRs to avoid ServiceCidrOverlapExistingSubnetsCidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    docker_bridge_cidr  = var.docker_bridge_cidr
  }

  tags = var.tags
}
