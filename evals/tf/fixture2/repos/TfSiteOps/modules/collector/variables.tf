variable "name" {
  description = "Name of the collector."
  type        = string
}

variable "retention_days" {
  description = "How long collected records are kept."
  type        = number
  default     = 30
}

variable "pop_ids" {
  description = "Points of presence to collect from."
  type        = list(string)
  default     = []
}
