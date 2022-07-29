terraform {
  backend "gcs" {
    bucket = "opentargets-eu-dev-terraform"
    prefix = "pos"
  }
}