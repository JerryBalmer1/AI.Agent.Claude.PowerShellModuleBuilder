resource "time_static" "created" {}

locals {
  tags = {
    owner       = var.owner
    environment = var.environment
    created     = time_static.created.rfc3339
  }
}
