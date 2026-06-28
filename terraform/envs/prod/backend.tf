terraform {
  required_version = ">= 1.6"
  backend "s3" {
    key     = "prod/terraform.tfstate"
    encrypt = true
  }
}
