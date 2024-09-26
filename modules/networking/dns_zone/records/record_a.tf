resource "azurerm_dns_a_record" "a" {
  for_each = {
    for key, value in try(var.records.a, {}) : key => value
    if try(value.resource_id, null) == null
  }

  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = try(each.value.ttl, 300)
  records             = try(each.value.records, null)
  tags                = merge(var.base_tags, try(each.value.tags, {}))
}

resource "azurerm_dns_a_record" "a_dns_zone_record" {
  for_each = {
    for key, value in try(var.records.a, {}) : key => value
    if try(value.resource_id.dns_zone_record, null) != null
  }

  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300 # Looks like cannot set another value than 300 when using target_resource_id
  tags                = merge(var.base_tags, try(each.value.tags, {}))
  target_resource_id  = azurerm_dns_a_record.a[each.value.resource_id.dns_zone_record.key].id
}

resource "azurerm_dns_a_record" "a_public_ip_address" {
  for_each = {
    for key, value in try(var.records.a, {}) : key => value
    #if try(value.resource_id.public_ip_address, null) != null
    if try(value.resource_id.static_site, value.resource_id.public_ip_address, null) != null #CLDSVC-v2024.09.18.9-5.5.5#
  }

  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300 # Looks like cannot set another value than 300 when using target_resource_id
  tags                = merge(var.base_tags, try(each.value.tags, {}))
  #target_resource_id  = var.resource_ids.public_ip_addresses[try(each.value.resource_id.public_ip_address.lz_key, var.client_config.landingzone_key)][each.value.resource_id.public_ip_address.key].id
  target_resource_id  =  try(var.resource_ids.public_ip_addresses[try(each.value.resource_id.public_ip_address.lz_key, var.client_config.landingzone_key)][each.value.resource_id.public_ip_address.key].id, var.resource_ids.static_sites[try(each.value.resource_id.static_site.lz_key, var.client_config.landingzone_key)][each.value.resource_id.static_site.key].id) #CLDSVC-v2024.09.18.9-5.5.5#
}