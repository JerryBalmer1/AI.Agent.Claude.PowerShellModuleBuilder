output "document" {
  description = "The assembled policy document."
  value       = local.document
}

output "steward" {
  description = "Team accountable for the policy."
  value       = var.steward
}
