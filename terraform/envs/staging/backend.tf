terraform {
  required_version = ">= 1.6"
  backend "s3" {
    key     = "staging/terraform.tfstate"
    encrypt = true
  }
}
