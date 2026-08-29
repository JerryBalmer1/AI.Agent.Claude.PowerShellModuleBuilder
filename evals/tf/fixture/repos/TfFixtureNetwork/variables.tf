variable "network_name" {
  description = "Name of the network this configuration describes."
  type        = string
  default     = "fixture-net"
}

variable "address_space" {
  description = "The CIDR the whole network is carved out of."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.address_space))
    error_message = "address_space must be a valid CIDR block."
  }
}

variable "segment_index" {
  description = "Which sub-block of address_space this segment takes."
  type        = number
  default     = 1
}

variable "subnet_count" {
  description = "How many subnets the segment creates."
  type        = number
  default     = 2
}

variable "enable_egress" {
  description = "Whether the segment provisions an egress marker."
  type        = bool
  default     = true
}
