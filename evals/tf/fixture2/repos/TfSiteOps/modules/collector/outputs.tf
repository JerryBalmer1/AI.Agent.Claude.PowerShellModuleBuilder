output "collected_ids" {
  description = "Identifiers the collector gathered."
  value       = var.pop_ids
}

output "tag" {
  description = "The tag the shared module produced for this collector."
  value       = module.common.tag
}

output "retention_days" {
  description = "How long collected records are kept."
  value       = var.retention_days
}
