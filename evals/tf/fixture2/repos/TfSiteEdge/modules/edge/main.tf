locals {
  pop_prefix = "${var.name}-pop"
}

module "pop" {
  source = "./modules/pop"

  count = var.pop_count

  name         = "${local.pop_prefix}-${count.index}"
  region       = var.region
  probe_window = var.probe_window
}

data "http" "health" {
  url = "https://${var.name}.example.invalid/health"
}

resource "terraform_data" "edge" {
  input = local.pop_prefix
}
