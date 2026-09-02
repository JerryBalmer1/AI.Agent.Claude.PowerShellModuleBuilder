variable "name" {
  description = "Name of the edge."
  type        = string
}

variable "region" {
  description = "Region the edge runs in."
  type        = string
  default     = "north"
}

variable "pop_count" {
  description = "How many points of presence to create."
  type        = number
  default     = 1

  validation {
    condition     = var.pop_count >= 1 && var.pop_count <= 8
    error_message = "pop_count must be between 1 and 8."
  }
}

variable "probe_window" {
  description = "Seconds a probe result stays current."
  type        = number
  default     = 120
}

variable "terminate_tls" {
  description = "Whether this edge terminates TLS."
  type        = bool
  default     = false
}
