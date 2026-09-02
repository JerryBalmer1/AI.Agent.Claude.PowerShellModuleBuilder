output "endpoint" {
  description = "Where this edge answers."
  value       = var.terminate_tls ? "https://${var.name}.example.invalid" : "http://${var.name}.example.invalid"
}

output "pop_ids" {
  description = "Identifiers of every point of presence."
  value       = module.pop[*].id
}

output "plan_summary" {
  description = "How many points of presence this edge plans, and where."
  value       = "${var.pop_count} pop(s) in ${var.region}"
}
