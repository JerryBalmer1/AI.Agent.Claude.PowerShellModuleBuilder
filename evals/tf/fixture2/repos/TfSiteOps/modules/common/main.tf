locals {
  tag = "${var.layer}/${var.name}"
}

resource "terraform_data" "common" {
  input = local.tag
}
