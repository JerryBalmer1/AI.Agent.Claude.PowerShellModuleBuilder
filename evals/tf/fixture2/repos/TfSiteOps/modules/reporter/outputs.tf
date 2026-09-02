output "report" {
  description = "The rendered report."
  value       = "${module.common.tag}.${var.format}"
}

output "name" {
  description = "Name of the reporter."
  value       = var.name
}
