terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  # Comment this backend block out initially if you haven't created a storage bucket for state yet
  backend "gcs" {
    bucket = "gcp-finops-monitor-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
