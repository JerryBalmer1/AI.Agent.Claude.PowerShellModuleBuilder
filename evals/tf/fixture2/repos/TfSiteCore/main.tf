locals {
  code_slug = lower(replace(var.site_code, "_", "-"))
}

module "label" {
  source = "./modules/label"

  slug   = local.code_slug
  region = var.region
}

module "policy" {
  source = "./modules/policy"

  steward = var.steward
  region  = var.region
}

resource "tls_private_key" "site" {
  algorithm = "ED25519"
}
