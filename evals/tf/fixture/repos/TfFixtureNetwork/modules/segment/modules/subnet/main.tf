# Third level. Nothing below this.

resource "null_resource" "subnet" {
  triggers = {
    name       = var.name
    cidr       = var.cidr
    segment_id = var.segment_id
  }
}
