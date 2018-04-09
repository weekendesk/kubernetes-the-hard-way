provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    encrypt = "true"
    bucket  = "k8s-1.9-tfstate-mbenabda.weekendesk.458736027585"
    region  = "eu-west-1"
    key     = "k8s19-the-hard-way-mbenabda/terraform.tfstate"
  }
}
