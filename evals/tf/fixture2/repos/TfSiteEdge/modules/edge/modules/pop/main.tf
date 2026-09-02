locals {
  probe_name = "${var.name}-probe"
}

module "probe" {
  source = "./modules/probe"

  name   = local.probe_name
  window = var.probe_window
}

resource "terraform_data" "pop" {
  input = var.name
}
