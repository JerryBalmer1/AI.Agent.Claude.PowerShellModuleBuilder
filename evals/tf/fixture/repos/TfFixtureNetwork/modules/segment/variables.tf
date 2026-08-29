variable "name" {
  description = "Segment name, supplied by the root."
  type        = string
}

variable "cidr" {
  description = "CIDR block this segment owns."
  type        = string
}

variable "subnet_count" {
  description = "How many subnets to create."
  type        = number
  default     = 1

  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 16
    error_message = "subnet_count must be between 1 and 16."
  }
}

variable "enable_egress" {
  description = "Whether to write an egress marker."
  type        = bool
  default     = false
}
