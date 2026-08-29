# TfFixtureShared root.
#
# The root here exists to make the repository a valid configuration and to
# give the two child modules a caller. Nothing outside this repository calls
# this root - TfFixtureApp sources modules/naming and modules/tags directly by
# git URL, which is the cross-repository case the fixture is for.

locals {
  # A local computed from a variable, consumed by a module block. The shortest
  # form of the traceability chain the graph has to carry.
  effective_prefix = var.prefix != "" ? var.prefix : "shared"
}

module "naming" {
  source = "./modules/naming"

  prefix      = local.effective_prefix
  environment = var.environment
}

module "tags" {
  source = "./modules/tags"

  owner       = var.owner
  environment = var.environment
}
