terraform {
  required_version = "~> 1.7.0"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0, < 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}
