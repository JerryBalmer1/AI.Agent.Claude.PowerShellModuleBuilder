variable "prefix" {
  description = "Name prefix applied to every generated name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test, prod."
  }
}

variable "owner" {
  description = "Team accountable for what these tags are attached to."
  type        = string
  default     = "platform"
}

variable "unused_retention_days" {
  description = "Declared and referenced by nothing. The absence case: a graph that invents a reference for this is wrong."
  type        = number
  default     = 30
}
