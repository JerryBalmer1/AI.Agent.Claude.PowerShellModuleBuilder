output "service_endpoint" {
  description = "Where the service answers."
  value       = module.service.endpoint
}

output "instance_name" {
  description = "Generated instance name."
  value       = random_pet.instance.id
}

output "applied_tags" {
  description = "The tag map that reached the service."
  value       = module.service.tags
}
