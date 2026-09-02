variable "name" {
  description = "Name of the probe."
  type        = string
}

variable "window" {
  description = "Seconds this probe's result stays current."
  type        = number
  default     = 60
}
