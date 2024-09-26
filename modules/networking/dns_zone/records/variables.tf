variable "base_tags" {
  default = {}
}
variable "client_config" {}
variable "resource_group_name" {}
variable "records" {}
variable "target_resources" {
  default = {}
}
variable "zone_name" {}
variable "resource_ids" {
  default = {}
}
variable "static_sites_url" {

 default = {}

 description = "CLDSVC - map containing static web app configurations in remote landingzones"

}#CLDSVC-v2024.09.18.9-5.5.5#