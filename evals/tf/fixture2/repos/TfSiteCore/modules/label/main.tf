locals {
  full = "${var.slug}-${var.region}"
}

resource "tls_private_key" "label" {
  algorithm = "ED25519"
}
