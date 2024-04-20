variable "location" {
  type    = string
  default = "UK South"
}

variable "resource_group_name" {
  type = string
}

variable "container_registry_name" {
  type = string
}

variable "image_name" {
  type = string
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "null_resource" "docker_push" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<-EOT
      docker build ../. -t ${azurerm_container_registry.acr.login_server}/${var.image_name}
      docker login ${azurerm_container_registry.acr.login_server} -u ${azurerm_container_registry.acr.admin_username} --password-stdin ${azurerm_container_registry.acr.admin_password}
      docker push ${azurerm_container_registry.acr.login_server}/${var.image_name}
    EOT
  }
}

resource "azurerm_storage_account" "aci_caddy" {
  name                      = "rustwebappacicaddy"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "aci_caddy" {
  name                 = "aci-caddy-data"
  storage_account_name = azurerm_storage_account.aci_caddy.name
  quota                = 5
}

resource "azurerm_container_group" "container" {
  name                = "${var.image_name}-instance"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label      = "rust-web-app-instance"

  depends_on = [
    null_resource.docker_push
  ]

  container {
    name   = var.image_name
    image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}"
    cpu    = 1
    memory = 1

    ports {
      port     = 8000
      protocol = "TCP"
    }
  }

  container {
    name   = "caddy"
    image  = "caddy:latest"
    cpu    = 1
    memory = 1

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    volume {
      name                 = "aci-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.aci_caddy.name
      storage_account_key  = azurerm_storage_account.aci_caddy.primary_access_key
      share_name           = azurerm_storage_share.aci_caddy.name
    }

    commands = ["caddy", "reverse-proxy", "--from", "jakef.dev", "--to", "localhost:8000"]
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }
}