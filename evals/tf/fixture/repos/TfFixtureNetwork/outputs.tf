output "segment_id" {
  description = "Identifier of the segment, consumed by TfFixtureApp."
  value       = module.segment.id
}

output "subnet_ids" {
  description = "Identifiers of every subnet, consumed by TfFixtureApp."
  value       = module.segment.subnet_ids
}

output "network_name" {
  description = "Echo of the network name, for a downstream caller."
  value       = var.network_name
}
