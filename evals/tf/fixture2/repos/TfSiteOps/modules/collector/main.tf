locals {
  collector_name = "${var.name}-collector"
}

module "common" {
  source = "../common"

  name  = local.collector_name
  layer = "collector"
}

resource "terraform_data" "collector" {
  input = var.pop_ids
}
