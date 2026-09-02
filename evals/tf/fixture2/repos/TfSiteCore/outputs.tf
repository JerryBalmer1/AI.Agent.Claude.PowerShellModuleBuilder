output "label_prefix" {
  description = "Prefix every site name is built from."
  value       = module.label.prefix
}

output "label_short" {
  description = "The label without its region suffix."
  value       = module.label.short
}

output "policy_document" {
  description = "The operating policy applied across the site."
  value       = module.policy.document
}
