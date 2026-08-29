# Fourth level of the tag chain, and the end of it.

resource "null_resource" "worker" {
  triggers = merge(var.tags, { worker = var.name })
}
