variable "name" {
  description = "Name of this point of presence."
  type        = string
}

variable "region" {
  description = "Region this point of presence sits in."
  type        = string
  default     = "north"
}

variable "probe_window" {
  description = "Seconds a probe result stays current."
  type        = number
  default     = 120
}
