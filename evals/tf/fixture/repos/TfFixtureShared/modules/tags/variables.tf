variable "owner" {
  description = "Team accountable for the tagged thing."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}
