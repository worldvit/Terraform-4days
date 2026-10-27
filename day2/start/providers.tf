provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Course = "tf4d"
      Day    = "day2"
    }
  }
}
