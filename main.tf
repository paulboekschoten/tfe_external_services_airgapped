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

resource "aws_subnet" "tfe_public" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet("10.200.0.0/16", 8, 0)

  tags = {
    Name = "${var.enviroment_name}-subnet-public"
  }
}

resource "aws_subnet" "tfe_private" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet("10.200.0.0/16", 8, 1)

  tags = {
    Name = "${var.enviroment_name}-subnet-private"
  }
}