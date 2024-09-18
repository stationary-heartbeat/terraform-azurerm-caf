module "records" {
  source     = "./records"
  count      = try(var.settings.records, null) == null ? 0 : 1
  depends_on = [azurerm_dns_zone.dns_zone]

  base_tags           = var.base_tags
  client_config       = var.client_config
  resource_group_name = var.resource_group_name
  #records             = var.settings.records
  records             = try(var.static_sites_url[each.value.lz_key][each.value.key].default_host_name, var.settings.records, null) #CLDSVC-v2024.09.18.9-5.5.5#
  resource_ids        = var.resource_ids
  zone_name           = local.dns_zone_name
}