terraform {
  required_version = ">= 1.4.0, < 1.10.0"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.4"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.6.0"
    }
  }
}
