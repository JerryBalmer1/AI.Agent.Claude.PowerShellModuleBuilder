locals {
  # The third link: the value arrives as a variable from the root, becomes a
  # local here, and is passed down to a nested module.
  subnet_prefix = "${var.name}-sn"
}

module "subnet" {
  source = "./modules/subnet"

  count = var.subnet_count

  name       = "${local.subnet_prefix}-${count.index}"
  cidr       = cidrsubnet(var.cidr, 4, count.index)
  segment_id = null_resource.segment.id
}

resource "null_resource" "segment" {
  triggers = {
    name = var.name
    cidr = var.cidr
  }
}

resource "local_file" "egress_marker" {
  count = var.enable_egress ? 1 : 0

  content  = "egress for ${var.name}"
  filename = "${path.module}/egress.txt"
}
