variable "prefix" {
  description = "Name prefix."
  type        = string

  validation {
    condition     = length(var.prefix) > 0
    error_message = "prefix must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}
