provider "hcloud" {
  token = var.hetzner_api_token
}

locals {
  # Maps location code → datacenter name.
  # hcloud_primary_ip requires a datacenter; hcloud_server takes a location.
  # Users set var.location once; everything derives from it.
  location_to_datacenter = {
    fsn1 = "fsn1-dc14"
    nbg1 = "nbg1-dc3"
    hel1 = "hel1-dc2"
    ash  = "ash-dc1"
    hil  = "hil-dc1"
  }

  datacenter = local.location_to_datacenter[var.location]
}
