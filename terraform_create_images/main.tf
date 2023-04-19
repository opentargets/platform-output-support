// Open Targets Platform Infrastructure
// Author: Cinzia Malangone <cinzia.malangone@gmail.com>

// --- Provider Configuration --- //
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.55.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.55.0"
    }
  }
}

provider "google" {
  region  = var.config_gcp_default_region
  project = var.config_project_id
  zone    = var.config_gcp_default_zone
}


provider "google-beta" {
  project = var.config_project_id
  region  = var.config_gcp_default_region
  zone    = var.config_gcp_default_zone
}
