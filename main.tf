provider "azurerm" {
 # version = "=2.1.0"
  features {}
}

module "tag-ressource" {
  source  = "app.terraform.io/PersoPierre/tag-ressource/azurerm"
  version = "0.0.1"

  namespace = {
    ent_code  =lookup(var.tags, "ent","")
    dept_code =lookup(var.tags, "dept","")
    env_code  =lookup(var.tags, "env","")
    type_code =lookup(var.tags, "type","")
  }
  free_name = var.tfp_name
}

data "azurerm_resource_group" "RG1" {
  name     = var.rg_name
}

resource "azurerm_traffic_manager_profile" "tfp" {
  name                = module.tag-ressource.generated_values.name
  resource_group_name = data.azurerm_resource_group.RG1.name

  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "${module.tag-ressource.generated_values.name}dns"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_endpoint" "tfpe" {
  name                = "${module.tag-ressource.generated_values.name}endpoint"
  resource_group_name = data.azurerm_resource_group.RG1.name
  profile_name        = azurerm_traffic_manager_profile.tfp.name
  target_ressource_id = data.azurerm_app_service.id
  type                = "azureEndpoints"
  weight              = 100
}