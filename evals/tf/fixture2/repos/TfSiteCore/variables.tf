variable "site_code" {
  description = "Short code identifying the site."
  type        = string
  default     = "core"
}

variable "region" {
  description = "Region the site runs in."
  type        = string
  default     = "north"

  validation {
    condition     = contains(["north", "south", "central"], var.region)
    error_message = "region must be one of north, south, central."
  }
}

variable "steward" {
  description = "Team that maintains the site."
  type        = string
  default     = "site-platform"
}

variable "archive_retention_weeks" {
  description = "How many weeks archived bundles are kept."
  type        = number
  default     = 12
}
