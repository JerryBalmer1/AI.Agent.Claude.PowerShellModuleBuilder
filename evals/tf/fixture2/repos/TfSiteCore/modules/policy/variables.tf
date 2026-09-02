variable "steward" {
  description = "Team accountable for the policy."
  type        = string
}

variable "region" {
  description = "Region the policy covers."
  type        = string
  default     = "north"
}

variable "max_sessions" {
  description = "Upper bound on concurrent sessions."
  type        = number
  default     = 50

  validation {
    condition     = var.max_sessions > 0
    error_message = "max_sessions must be greater than zero."
  }
}
