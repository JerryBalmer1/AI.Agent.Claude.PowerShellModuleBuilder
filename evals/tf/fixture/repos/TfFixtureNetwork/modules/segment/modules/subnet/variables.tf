variable "name" {
  description = "Subnet name, built by the segment from its own local."
  type        = string
}

variable "cidr" {
  description = "CIDR block for this subnet."
  type        = string
}

variable "segment_id" {
  description = "The segment this subnet belongs to."
  type        = string
}
