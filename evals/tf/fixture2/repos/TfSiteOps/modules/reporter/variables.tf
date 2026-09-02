variable "name" {
  description = "Name of the reporter."
  type        = string
}

variable "format" {
  description = "Format the report is written in."
  type        = string
  default     = "json"

  validation {
    condition     = contains(["json", "text"], var.format)
    error_message = "format must be json or text."
  }
}
