terraform {
  required_version = ">= 1.6.0"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }
}
