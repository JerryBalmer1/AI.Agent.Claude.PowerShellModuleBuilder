locals {
  ops_name = "${var.site_name}-ops"

  edge_pop_ids = module.edge.pop_ids
}

module "edge" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteEdge?ref=main"

  site_name = var.site_name
  region    = var.region
}

module "policy" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteCore//modules/policy?ref=main"

  steward = var.site_name
  region  = var.region
}

module "collector" {
  source = "./modules/collector"

  name           = local.ops_name
  retention_days = var.retention_days
  pop_ids        = local.edge_pop_ids
}

module "reporter" {
  source = "./modules/reporter"

  name   = local.ops_name
  format = var.report_format
}

module "vault_archive" {
  source = "../site-archive/modules/vault"

  retain_weeks = 6
}

data "archive_file" "bundle" {
  type        = "zip"
  source_dir  = "${path.module}/records"
  output_path = "${path.module}/records.zip"
}
