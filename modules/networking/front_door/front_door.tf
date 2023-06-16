resource "azurecaf_name" "frontdoor" {
  name          = var.settings.name
  resource_type = "azurerm_frontdoor"
  prefixes      = try(var.settings.global_settings.prefixes, var.global_settings.prefixes)
  random_length = try(var.settings.global_settings.random_length, var.global_settings.random_length)
  clean_input   = true
  passthrough   = try(var.settings.global_settings.passthrough, var.global_settings.passthrough)
  use_slug      = try(var.settings.global_settings.use_slug, var.global_settings.use_slug)
}

# Ref : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor
# Tested with AzureRM 2.57.0

resource "azurerm_frontdoor" "frontdoor" {
  name                                         = azurecaf_name.frontdoor.result
  resource_group_name                          = var.resource_group_name
  enforce_backend_pools_certificate_name_check = try(var.settings.certificate_name_check, false)
  tags                                         = local.tags

  dynamic "routing_rule" {
    for_each = var.settings.routing_rule

    content {
      name               = routing_rule.value.name
      accepted_protocols = routing_rule.value.accepted_protocols
      patterns_to_match  = routing_rule.value.patterns_to_match

      frontend_endpoints = flatten(
        [
          for key in try(routing_rule.value.frontend_endpoint_keys, []) : [
            var.settings.frontend_endpoints[key].name
          ]
        ]
      )

      dynamic "forwarding_configuration" {
        for_each = lower(routing_rule.value.configuration) == "forwarding" ? [routing_rule.value.forwarding_configuration] : []

        content {
          backend_pool_name                     = routing_rule.value.forwarding_configuration.backend_pool_name
          cache_enabled                         = routing_rule.value.forwarding_configuration.cache_enabled
          cache_use_dynamic_compression         = routing_rule.value.forwarding_configuration.cache_use_dynamic_compression #default: false
          cache_query_parameter_strip_directive = routing_rule.value.forwarding_configuration.cache_query_parameter_strip_directive
          custom_forwarding_path                = routing_rule.value.forwarding_configuration.custom_forwarding_path
          forwarding_protocol                   = routing_rule.value.forwarding_configuration.forwarding_protocol
        }
      }
      dynamic "redirect_configuration" {
        for_each = lower(routing_rule.value.configuration) == "redirecting" ? [routing_rule.value.redirect_configuration] : []

        content {
          custom_host         = routing_rule.value.redirect_configuration.custom_host
          redirect_protocol   = routing_rule.value.redirect_configuration.redirect_protocol
          redirect_type       = routing_rule.value.redirect_configuration.redirect_type
          custom_fragment     = routing_rule.value.redirect_configuration.custom_fragment
          custom_path         = routing_rule.value.redirect_configuration.custom_path
          custom_query_string = routing_rule.value.redirect_configuration.custom_query_string
        }
      }
    }
  }

  backend_pools_send_receive_timeout_seconds = try(var.settings.backend_pools_send_receive_timeout_seconds, 60)
  load_balancer_enabled                      = try(var.settings.load_balancer_enabled, true)
  friendly_name                              = try(var.settings.backend_pool.name, null)


  dynamic "backend_pool_load_balancing" {
    for_each = var.settings.backend_pool_load_balancing

    content {
      name                            = backend_pool_load_balancing.value.name
      sample_size                     = backend_pool_load_balancing.value.sample_size
      successful_samples_required     = backend_pool_load_balancing.value.successful_samples_required
      additional_latency_milliseconds = backend_pool_load_balancing.value.additional_latency_milliseconds
    }
  }

  dynamic "backend_pool_health_probe" {
    for_each = var.settings.backend_pool_health_probe

    content {
      name                = backend_pool_health_probe.value.name
      path                = backend_pool_health_probe.value.path
      protocol            = backend_pool_health_probe.value.protocol
      interval_in_seconds = backend_pool_health_probe.value.interval_in_seconds
    }
  }

  dynamic "backend_pool" {
    for_each = var.settings.backend_pool

    content {
      name                = backend_pool.value.name
      load_balancing_name = var.settings.backend_pool_load_balancing[backend_pool.value.load_balancing_key].name
      health_probe_name   = var.settings.backend_pool_health_probe[backend_pool.value.health_probe_key].name

      dynamic "backend" {
        for_each = backend_pool.value.backend
        content {
          enabled     = backend.value.enabled
          address     = backend.value.address
          host_header = backend.value.host_header
          http_port   = backend.value.http_port
          https_port  = backend.value.https_port
          priority    = backend.value.priority
          weight      = backend.value.weight
        }
      }
    }
  }

  dynamic "frontend_endpoint" {
    for_each = var.settings.frontend_endpoints

    content {
      name                                    = frontend_endpoint.value.name
      host_name                               = try(frontend_endpoint.value.host_name, format("%s.azurefd.net", azurecaf_name.frontdoor.result))
      session_affinity_enabled                = frontend_endpoint.value.session_affinity_enabled
      session_affinity_ttl_seconds            = frontend_endpoint.value.session_affinity_ttl_seconds
      web_application_firewall_policy_link_id = try(frontend_endpoint.value.front_door_waf_policy.key, null) == null ? null : var.front_door_waf_policies[try(frontend_endpoint.value.front_door_waf_policy.lz_key, var.client_config.landingzone_key)][frontend_endpoint.value.front_door_waf_policy.key].id
    }
  }
}


resource "azurerm_frontdoor_custom_https_configuration" "frontdoor_custom_https_off" {
  for_each = {
    for key, value in var.settings.frontend_endpoints : key => value
    if try(value.custom_https_provisioning_enabled, false) == false
  }
  // The above if filters out custom https 

  frontend_endpoint_id              = azurerm_frontdoor.frontdoor.frontend_endpoint[0].id
  custom_https_provisioning_enabled = try(each.value.custom_https_provisioning_enabled, false)

  // don't include the custom block here as it should not be added for default front ends.
}

resource "azurerm_frontdoor_custom_https_configuration" "frontdoor_custom_https_on" {
  for_each = {
   for key, value in var.settings.frontend_endpoints : key => value
    if try(value.custom_https_provisioning_enabled, false) == true
   }

  frontend_endpoint_id              = azurerm_frontdoor.frontdoor.frontend_endpoint[1].id
  custom_https_provisioning_enabled = try(each.value.custom_https_provisioning_enabled, false)

  custom_https_configuration {
    certificate_source                         = each.value.custom_https_configuration.certificate_source
    azure_key_vault_certificate_vault_id       = coalesce(
        try(each.value.custom_https_configuration.keyvault.id, null),
        try(var.keyvaults[each.value.custom_https_configuration.keyvault.lz_key][each.value.custom_https_configuration.keyvault.key].id, null),
        try(var.keyvaults[var.client_config.landingzone_key][each.value.custom_https_configuration.value.keyvault.key].id, null),
        try(each.value.custom_https_configuration.azure_key_vault_certificate_vault_id, null),
        try(var.keyvault_certificate_requests[var.client_config.landingzone_key][each.value.custom_https_configuration.certificate.key].keyvault_id, null),
        try(var.keyvault_certificate_requests[each.value.custom_https_configuration.certificate.lz_key][each.value.custom_https_configuration.certificate.key].keyvault_id, null)
      )
    azure_key_vault_certificate_secret_name    = coalesce(
        try(each.value.custom_https_configuration.keyvault.secret_name, null),
        try(each.value.custom_https_configuration.azure_key_vault_certificate_secret_name, null),
        try(var.keyvault_certificate_requests[var.client_config.landingzone_key][each.value.custom_https_configuration.certificate.key].name, null),
        try(var.keyvault_certificate_requests[each.value.custom_https_configuration.certificate.lz_key][each.value.custom_https_configuration.certificate.key].name, null)
      )
    azure_key_vault_certificate_secret_version = try(coalesce(
        try(each.value.custom_https_configuration.keyvault.secret_version, null),
        try(each.value.custom_https_configuration.azure_key_vault_certificate_secret_version, null),
        try(var.keyvault_certificate_requests[var.client_config.landingzone_key][each.value.custom_https_configuration.certificate.key].version, null),
        try(var.keyvault_certificate_requests[each.value.custom_https_configuration.certificate.lz_key][each.value.custom_https_configuration.certificate.key].version, null),
        try(each.value.custom_https_configuration.keyvault.secret_version, null)
        ), null)
  }
}
