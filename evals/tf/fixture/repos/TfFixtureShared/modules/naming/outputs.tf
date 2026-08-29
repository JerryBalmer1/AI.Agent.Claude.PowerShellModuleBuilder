output "prefix" {
  description = "The qualified prefix, environment included."
  value       = local.qualified
}

output "unique_suffix" {
  description = "A random suffix stable for the life of the state."
  value       = random_string.suffix.result
}
