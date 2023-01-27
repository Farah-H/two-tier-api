terraform {
  required_version = "~> 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.50.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }

  backend "s3" {
    bucket         = "farah-terraform-state-files"
    key            = "prod/eu-west-1/terraform.tfstate"
    dynamodb_table = "farah-terraform-state-lock"
    region         = "eu-west-1"
    encrypt        = true
  }
}
