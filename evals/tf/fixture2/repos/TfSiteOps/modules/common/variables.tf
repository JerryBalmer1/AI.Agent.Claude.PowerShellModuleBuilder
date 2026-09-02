variable "name" {
  description = "Name of the calling component."
  type        = string
}

variable "layer" {
  description = "Which part of the operations stack is calling."
  type        = string
  default     = "shared"
}
