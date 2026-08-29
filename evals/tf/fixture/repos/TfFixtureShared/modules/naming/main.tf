resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # variable -> local, then local -> output. The second link of the chain.
  qualified = "${var.prefix}-${var.environment}"
}
