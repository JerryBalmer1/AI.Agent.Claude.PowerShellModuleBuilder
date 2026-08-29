output "name_prefix" {
  description = "The prefix every name in this estate is built from."
  value       = module.naming.prefix
}

output "common_tags" {
  description = "Tags every resource carries."
  value       = module.tags.tags
}
