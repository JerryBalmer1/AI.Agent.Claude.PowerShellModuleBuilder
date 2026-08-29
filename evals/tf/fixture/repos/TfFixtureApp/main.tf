# TfFixtureApp root. The traceability showcase.
#
# THE CHAIN, and the reason this repository exists:
#
#   var.tags  ->  local.merged_tags  ->  module.service.tags  ->  module.worker.tags
#
# Four levels, crossing a module boundary twice. A graph that carries it as
# `references` and `passes-to` edges has understood the configuration; one
# that reports four unrelated nodes has not.

locals {
  # variable -> local. Link one.
  merged_tags = merge(var.tags, {
    application = var.application_name
    segment     = var.network_segment_id
  })

  service_name = "${var.application_name}-svc"
}

# Cross-repository source, by git URL. Inert text as far as parsing is
# concerned - no credential appears here or anywhere in this fixture.
module "naming" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfFixtureShared//modules/naming?ref=main"

  prefix      = var.application_name
  environment = var.environment
}

module "tags" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfFixtureShared//modules/tags?ref=main"

  owner       = var.owner
  environment = var.environment
}

# Own nested module. local -> module. Link two.
module "service" {
  source = "./modules/service"

  name         = local.service_name
  tags         = local.merged_tags
  subnet_ids   = var.network_subnet_ids
  worker_count = var.worker_count
}

# A module sourced from a path that exists in no repository in this fixture.
# Deliberate: the unresolved-reference case. A producer that drops it reports
# a graph that looks complete and is not.
module "legacy" {
  source = "../shared-legacy/modules/archive"

  retention_days = 90
}

resource "random_pet" "instance" {
  length = 2
  prefix = local.service_name
}
