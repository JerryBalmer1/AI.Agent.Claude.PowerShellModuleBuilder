# TfFixtureNetwork root.
#
# Three module levels: this root calls modules/segment, which calls
# modules/segment/modules/subnet. The chain is the nested-module case.

locals {
  # variable -> local
  segment_name = "${var.network_name}-core"

  # A local computed from another local, so the chain is two links before it
  # reaches a module.
  segment_cidr = cidrsubnet(var.address_space, 4, var.segment_index)
}

module "segment" {
  source = "./modules/segment"

  name          = local.segment_name
  cidr          = local.segment_cidr
  subnet_count  = var.subnet_count
  enable_egress = var.enable_egress
}

resource "terraform_data" "network_marker" {
  input = local.segment_name
}
