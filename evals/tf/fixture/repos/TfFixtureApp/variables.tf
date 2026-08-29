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

variable "network_segment_id" {
  description = "TfFixtureNetwork's segment_id output, supplied by the caller. The cross-repository output-reference case."
  type        = string
  default     = ""
}

variable "network_subnet_ids" {
  description = "TfFixtureNetwork's subnet_ids output, supplied by the caller."
  type        = list(string)
  default     = []
}

variable "worker_count" {
  description = "How many workers the service runs."
  type        = number
  default     = 2
}
