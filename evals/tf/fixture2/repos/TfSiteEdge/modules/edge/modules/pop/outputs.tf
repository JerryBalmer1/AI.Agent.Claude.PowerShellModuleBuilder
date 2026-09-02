output "id" {
  description = "Identifier of this point of presence."
  value       = terraform_data.pop.output
}

output "probe_id" {
  description = "Identifier of the probe this point of presence runs."
  value       = module.probe.id
}

output "region" {
  description = "Region this point of presence sits in."
  value       = var.region
}
