locals {
  # Link three: the tags arrive as a variable and are extended before being
  # passed down again.
  service_tags = merge(var.tags, { tier = "service" })
}

module "worker" {
  source = "./modules/worker"

  count = var.worker_count

  name = "${var.name}-w${count.index}"
  tags = local.service_tags
}

resource "null_resource" "service" {
  triggers = local.service_tags
}
