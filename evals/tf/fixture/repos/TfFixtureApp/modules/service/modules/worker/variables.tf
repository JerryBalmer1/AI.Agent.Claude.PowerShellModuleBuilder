variable "name" {
  description = "Worker name."
  type        = string
}

variable "tags" {
  description = "Tags, arrived from the root by way of the service module. Link four."
  type        = map(string)
}
