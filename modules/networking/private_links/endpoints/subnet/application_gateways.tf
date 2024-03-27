module "application_gateways" {
  source = "../private_endpoint"
  for_each = {
    for key, value in try(var.private_endpoints.application_gateways, {}) : key => value
    if can(value.lz_key) == false
  }
  base_tags           = var.base_tags
  client_config       = var.client_config
  global_settings     = var.global_settings
  location            = var.vnet_location # The private endpoint must be deployed in the same region as the virtual network.
  name                = try(each.value.name, each.key)
  private_dns         = var.private_dns
  resource_group_name = can(each.value.resource_group_key) ? var.resource_groups[try(each.value.lz_key, var.client_config.landingzone_key)][each.value.resource_group_key].name : var.vnet_resource_group_name
  #resource_id         = try(each.value.private_service_connection.private_connection_resource_id, can(each.value.resource_id) ? each.value.resource_id : var.remote_objects.application_gateway_platforms[var.client_config.landingzone_key][try(each.value.key, each.key)].id)
  resource_id         = can(each.value.resource_id) ? each.value.resource_id : var.remote_objects.application_gateways[var.client_config.landingzone_key][try(each.value.key, each.key)].id
  settings            = each.value
  subnet_id           = var.subnet_id
  subresource_names   = toset(try(each.value.private_service_connection.subresource_names, ["appGwPrivateFrontendIpIPv4"]))
}
module "application_gateways_remote" {
  source = "../private_endpoint"
  for_each = {
    for key, value in try(var.private_endpoints.application_gateways, {}) : key => value
    if can(value.lz_key)
  }
  base_tags           = var.base_tags
  client_config       = var.client_config
  global_settings     = var.global_settings
  location            = var.vnet_location # The private endpoint must be deployed in the same region as the virtual network.
  name                = try(each.value.name, each.key)
  private_dns         = var.private_dns
  resource_group_name = can(each.value.resource_group_key) ? var.resource_groups[try(each.value.lz_key, var.client_config.landingzone_key)][each.value.resource_group_key].name : var.vnet_resource_group_name
  #resource_id         = try(each.value.private_service_connection.private_connection_resource_id, can(each.value.key) ? var.remote_objects.application_gateway_platforms[each.value.lz_key][each.value.key].id : var.remote_objects.application_gateway_platforms[each.value.lz_key][each.key].id)
  resource_id         = can(each.value.key) ? var.remote_objects.application_gateways[each.value.lz_key][each.value.key].id : var.remote_objects.application_gateways[each.value.lz_key][each.key].id
  settings            = each.value
  subnet_id           = var.subnet_id
  subresource_names   = toset(try(each.value.private_service_connection.subresource_names, ["appGwPrivateFrontendIpIPv4"]))
}