locals {
  document = {
    steward      = var.steward
    region       = var.region
    max_sessions = var.max_sessions
  }
}

resource "terraform_data" "policy" {
  input = local.document
}
