locals {
  reporter_name = "${var.name}-reporter"
}

module "common" {
  source = "../common"

  name  = local.reporter_name
  layer = "reporter"
}

data "external" "renderer" {
  program = ["echo", "{}"]
}
