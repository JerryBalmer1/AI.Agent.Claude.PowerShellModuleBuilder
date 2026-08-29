variable "name" {
  description = "Service name, built by the root from a local."
  type        = string
}

variable "tags" {
  description = "Tags from the root. Link two of the chain arrives here."
  type        = map(string)
}

variable "subnet_ids" {
  description = "Subnets the service is placed in, originally TfFixtureNetwork's output."
  type        = list(string)
  default     = []
}

variable "worker_count" {
  description = "How many workers to create."
  type        = number
  default     = 1
}
