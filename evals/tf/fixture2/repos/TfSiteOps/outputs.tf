output "edge_endpoint" {
  description = "Where the edge answers."
  value       = module.edge.edge_endpoint
}

output "collected_ids" {
  description = "Identifiers the collector gathered."
  value       = module.collector.collected_ids
}

output "report" {
  description = "The rendered report."
  value       = module.reporter.report
}

output "policy_steward" {
  description = "Team accountable for the applied policy."
  value       = module.policy.steward
}
