terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.41.0"
    }
  }

  required_version = "1.3.5"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "tfe" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.enviroment_name}-vpc"
  }
}