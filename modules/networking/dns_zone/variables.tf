variable "resource_group_name" {
  description = "(Required) The name of the resource group where to create the resource."
  type        = string
}
variable "client_config" {}
variable "settings" {}
variable "global_settings" {
  description = "Global settings object (see module README.md)"
}
variable "base_tags" {
  description = "Base tags for the resource to be inherited from the resource group."
  type        = map(any)
}
variable "resource_ids" {
  default = {}
}
variable "static_sites_url" {
  default = {}
}#CLDSVC-v2024.09.18.9-5.5.5#