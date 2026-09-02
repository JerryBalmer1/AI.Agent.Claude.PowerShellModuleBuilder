output "prefix" {
  description = "The full label prefix."
  value       = local.full
}

output "short" {
  description = "The label without its region suffix."
  value       = var.slug
}
