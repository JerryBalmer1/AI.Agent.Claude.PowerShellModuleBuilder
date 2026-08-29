output "endpoint" {
  description = "Where the service answers."
  value       = "https://${var.name}.example.invalid"
}

output "tags" {
  description = "The tags this service applied, after its own merge."
  value       = local.service_tags
}
