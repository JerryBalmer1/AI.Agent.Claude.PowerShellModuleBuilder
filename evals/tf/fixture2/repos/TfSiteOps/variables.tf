variable "site_name" {
  description = "Name of the site being operated."
  type        = string
  default     = "site-ops"
}

variable "region" {
  description = "Region the operations run in."
  type        = string
  default     = "north"
}

variable "retention_days" {
  description = "How long collected records are kept."
  type        = number
  default     = 45

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least one day."
  }
}

variable "report_format" {
  description = "Format the report is written in."
  type        = string
  default     = "json"
}
