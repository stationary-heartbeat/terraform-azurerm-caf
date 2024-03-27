terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }

}

locals {
  tags = var.base_tags ? merge(
    var.global_settings.tags,
    var.tags,
    try(var.settings.tags, null)
  ) : try(var.settings.tags, null)

  location = can(var.location) || can(var.settings.region) ? try(var.location, var.global_settings.regions[var.settings.region]) : var.resource_groups[try(var.settings.resource_group.lz_key, var.settings.lz_key, var.client_config.landingzone_key)][try(var.settings.resource_group.key, var.settings.resource_group_key)].location

  resource_group_name = can(var.resource_group_name) && var.resource_group_name != null ? var.resource_group_name : var.resource_groups[try(var.settings.resource_group.lz_key, var.settings.lz_key, var.client_config.landingzone_key)][try(var.settings.resource_group.key, var.settings.resource_group_key)].name

}

/*locals {
  module_tag = {
    "module" = basename(abspath(path.module))
  }
  tags = merge(var.base_tags, local.module_tag, try(var.settings.tags, null))

  location = can(var.settings.region) ? var.global_settings.regions[var.settings.region] : try(var.location, local.resource_group.location)
  resource_group = try(
    var.resource_groups[var.client_config.landingzone_key][var.settings.resource_group_key],
    var.resource_groups[var.settings.lz_key][var.settings.resource_group_key],
    var.resource_groups[var.client_config.landingzone_key][var.settings.resource_group.key],
    var.resource_groups[var.settings.resource_group.lz_key][var.settings.resource_group.key],
    null
  )
}*/
