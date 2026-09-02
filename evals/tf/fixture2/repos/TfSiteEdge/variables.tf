variable "site_name" {
  description = "Name of the site this edge fronts."
  type        = string
  default     = "site-edge"
}

variable "region" {
  description = "Region the edge runs in."
  type        = string
  default     = "north"

  validation {
    condition     = contains(["north", "south", "central"], var.region)
    error_message = "region must be one of north, south, central."
  }
}

variable "pop_count" {
  description = "How many points of presence the edge creates."
  type        = number
  default     = 3
}

variable "probe_interval_seconds" {
  description = "Seconds between probes."
  type        = number
  default     = 30
}

variable "enable_tls" {
  description = "Whether the edge terminates TLS."
  type        = bool
  default     = true
}
