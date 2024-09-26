resource "azurerm_dns_txt_record" "txt" {
  for_each = try(var.records.txt, {})

  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = try(each.value.ttl, 300)
  tags                = merge(var.base_tags, try(each.value.tags, {}))

  dynamic "record" {
    for_each = each.value.records

    content {
      value = record.value.value
      #value = try(var.static_sites_url[record.value.lz_key][record.value.key].custom_domain.txt_domain.validation_token, record.value.value) #CLDSVC-v2024.09.18.9-5.5.5#
    }
  }
}