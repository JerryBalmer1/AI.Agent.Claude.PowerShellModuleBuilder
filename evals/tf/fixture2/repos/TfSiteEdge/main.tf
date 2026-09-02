locals {
  edge_name = "${var.site_name}-edge"

  probe_window = var.probe_interval_seconds * 4
}

module "label" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteCore//modules/label?ref=main"

  slug   = var.site_name
  region = var.region
}

module "edge" {
  source = "./modules/edge"

  name          = local.edge_name
  region        = var.region
  pop_count     = var.pop_count
  probe_window  = local.probe_window
  terminate_tls = var.enable_tls
}

module "vendor_probe" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteVendor//modules/probe?ref=main"

  interval_seconds = var.probe_interval_seconds
}

resource "tls_private_key" "edge" {
  algorithm = "ED25519"
}
