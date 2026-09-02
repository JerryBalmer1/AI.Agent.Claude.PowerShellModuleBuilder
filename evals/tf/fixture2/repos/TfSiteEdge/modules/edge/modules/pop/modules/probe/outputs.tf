output "id" {
  description = "Identifier of the probe."
  value       = terraform_data.probe.output
}

output "name" {
  description = "Name of the probe."
  value       = var.name
}

output "window" {
  description = "Seconds this probe's result stays current."
  value       = var.window
}
