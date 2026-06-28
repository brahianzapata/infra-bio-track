terraform {
  required_version = ">= 1.6"
  backend "s3" {
    key     = "shared/terraform.tfstate"
    encrypt = true
  }
}
