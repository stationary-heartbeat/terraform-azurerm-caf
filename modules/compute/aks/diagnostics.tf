
module "diagnostics" {
  source = "../../diagnostics"
  count  = var.diagnostic_profiles == null ? 0 : 1

  resource_id       = azurerm_kubernetes_cluster.aks.id
  resource_location = local.location
  diagnostics       = var.diagnostics
  profiles          = var.diagnostic_profiles
}