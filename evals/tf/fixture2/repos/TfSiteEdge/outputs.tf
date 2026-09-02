output "edge_endpoint" {
  description = "Where the edge answers."
  value       = module.edge.endpoint
}

output "pop_ids" {
  description = "Identifiers of every point of presence."
  value       = module.edge.pop_ids
}

output "label_prefix" {
  description = "Prefix supplied by the shared label module."
  value       = module.label.prefix
}

output "region" {
  description = "Region the edge runs in, echoed for a downstream caller."
  value       = var.region
}
