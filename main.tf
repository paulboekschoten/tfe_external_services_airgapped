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

# vpc
resource "aws_vpc" "tfe" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

# public subnet
resource "aws_subnet" "tfe_public" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet("10.200.0.0/16", 8, 0)

  tags = {
    Name = "${var.environment_name}-subnet-public"
  }
}

# private subnet
resource "aws_subnet" "tfe_private" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet("10.200.0.0/16", 8, 1)

  tags = {
    Name = "${var.environment_name}-subnet-private"
  }
}

# internet gateway
resource "aws_internet_gateway" "tfe_igw" {
  vpc_id = aws_vpc.tfe.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}

# add igw to default vpc route table
resource "aws_default_route_table" "tfe" {
  default_route_table_id = aws_vpc.tfe.default_route_table_id

  route {
    cidr_block = local.all_ips
    gateway_id = aws_internet_gateway.tfe_igw.id
  }

  tags = {
    Name = "${var.environment_name}-rtb"
  }
}

# key pair
# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# key pair in aws
resource "aws_key_pair" "tfe" {
  key_name   = "${var.environment_name}-keypair"
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

# store private ssh key locally
resource "local_file" "tfesshkey" {
  content         = tls_private_key.rsa-4096.private_key_pem
  filename        = "${path.module}/tfesshkey.pem"
  file_permission = "0600"
}

# security group
resource "aws_security_group" "tfe_sg" {
  name = "${var.environment_name}-sg"

  tags = {
    Name = "${var.environment_name}-sg"
  }
}

# sg rule ssh inbound
resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.ssh_port
  to_port     = var.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule https inbound
resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.https_port
  to_port     = var.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule https inbound
resource "aws_security_group_rule" "allow_replicated_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.replicated_port
  to_port     = var.replicated_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule postgresql local vpc inbound
resource "aws_security_group_rule" "allow_postgresql_inbound_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.postgresql_port
  to_port     = var.postgresql_port
  protocol    = local.tcp_protocol
  cidr_blocks = [aws_vpc.tfe.cidr_block]
}

# sg rule all outbound
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = [local.all_ips]
}