terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.41.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.11.1"
    }
  }

  required_version = "1.3.5"
}

provider "aws" {
  region = var.region
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
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

# fetch ubuntu ami id for version 22.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# EC2 instance
resource "aws_instance" "tfe" {
  ami                    = data.aws_ami.ubuntu.image_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.tfe.key_name
  vpc_security_group_ids = [aws_security_group.tfe_sg.id]

  iam_instance_profile = aws_iam_instance_profile.tfe_profile.name

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = "${var.environment_name}-tfe"
  }
}

# create public ip
resource "aws_eip" "eip_tfe" {
  vpc = true
  tags = {
    Name = var.environment_name
  }
}

# associate public ip with instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.tfe.id
  allocation_id = aws_eip.eip_tfe.id
}

## route53 fqdn
# fetch zone
data "aws_route53_zone" "selected" {
  name         = var.route53_zone
  private_zone = false
}

# create record
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.fqdn
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip_tfe.public_ip]
}

## certficate let's encrypt
# create auth key
resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
}

# register
resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.cert_private_key.private_key_pem
  email_address   = var.cert_email
}
# get certificate
resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = local.fqdn

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.selected.zone_id
    }
  }
}

# store cert
resource "aws_acm_certificate" "cert" {
  private_key       = acme_certificate.certificate.private_key_pem
  certificate_body  = acme_certificate.certificate.certificate_pem
  certificate_chain = acme_certificate.certificate.issuer_pem
}

# s3 bucket
resource "aws_s3_bucket" "tfe" {
  bucket = "${var.environment_name}-bucket"

  tags = {
    Name = "${var.environment_name}-bucket"
  }
}

# disable all public bucket access
resource "aws_s3_bucket_public_access_block" "tfe" {
  bucket = aws_s3_bucket.tfe.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# instance profile
resource "aws_iam_instance_profile" "tfe_profile" {
  name = "${var.environment_name}-profile"
  role = aws_iam_role.tfe_s3_role.name
}

# iam role
resource "aws_iam_role" "tfe_s3_role" {
  name = "${var.environment_name}-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    tag-key = "${var.environment_name}-role"
  }
}

# role policy
resource "aws_iam_policy" "tfe_s3_policy" {
  name = "${var.environment_name}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListStorageLensConfigurations",
          "s3:ListAccessPointsForObjectLambda",
          "s3:GetAccessPoint",
          "s3:PutAccountPublicAccessBlock",
          "s3:GetAccountPublicAccessBlock",
          "s3:ListAllMyBuckets",
          "s3:ListAccessPoints",
          "s3:PutAccessPointPublicAccessBlock",
          "s3:ListJobs",
          "s3:PutStorageLensConfiguration",
          "s3:ListMultiRegionAccessPoints",
          "s3:CreateJob"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : "*"
      }
    ]
  })
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.tfe_s3_role.name
  policy_arn = aws_iam_policy.tfe_s3_policy.arn
}