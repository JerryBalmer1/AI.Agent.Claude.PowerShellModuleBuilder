variable "application_name" {
  description = "Name of the application this configuration deploys."
  type        = string
  default     = "fixture-app"
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
  description = "Team accountable for this application."
  type        = string
  default     = "app-team"
}

variable "tags" {
  description = "Base tags. Flows three levels: here, into the service module, and into its worker."
  type        = map(string)
  default     = { cost_centre = "cc-1234" }
}

variable "worker_count" {
  description = "How many workers the service runs."
  type        = number
  default     = 2
}
