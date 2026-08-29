output "id" {
  description = "The segment resource id."
  value       = null_resource.segment.id
}

output "subnet_ids" {
  description = "Every subnet id this segment created."
  value       = module.subnet[*].id
}
