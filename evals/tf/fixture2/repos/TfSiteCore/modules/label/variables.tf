variable "slug" {
  description = "Slug the label is built from."
  type        = string

  validation {
    condition     = length(var.slug) > 1
    error_message = "slug must be at least two characters long."
  }
}

variable "region" {
  description = "Region the label names."
  type        = string
  default     = "north"
}
