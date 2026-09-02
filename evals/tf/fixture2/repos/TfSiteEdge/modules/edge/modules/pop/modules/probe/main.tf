resource "terraform_data" "probe" {
  input = {
    name   = var.name
    window = var.window
  }
}
