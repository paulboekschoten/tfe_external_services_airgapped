# Terraform Enterprise Airgapped installation with valid certificates on AWS  
This repository installs an Airgapped Terraform Enterprise (TFE) with valid certificates in AWS on a Ubuntu virtual machine.  

This terraform code creates
- A VPC
- Subnets
- Internet gateway
- Route Table
- A key pair
- A security group
- Security group rules
- S3 Bucket
- PostgreSQL Database
- An Elastic IP
- A Route53 DNS entry
- Valid certificates
- An Ubuntu virtual machine (22.04)
  - Replicated configuration
  - TFE settings json
  - Install latest TFE
  - TFE Admin account

# Diagram
![](diagram/tfe_airgapped.png)

# Prerequisites
 - An AWS account with default VPC and internet access.
 - TFE Airgap installation file
 - A TFE license
 - Docker libraries

# How to install airgapped TFE with valid certficates on AWS


# TODO
- [ ] Create PostgreSQL database
- [ ] Install TFE 
  - [ ] Create settings.json
  - [ ] Create replicated.conf
  - [ ] Copy certificates
  - [ ] Copy license.rli
  - [ ] Create admin user
- [ ] Documentation

# DONE
- [x] Create manually
- [x] Add diagram
- [x] Create VPC
- [x] Create Subnets
- [x] Create Internet gateway
- [x] Change default Route Table
- [x] Create Key pair
- [x] Create security groups
- [x] Create a security group rules
- [x] Create an EC2 instance
- [x] Create EIP
- [x] Create DNS record
- [x] Create valid certificate
- [x] Create S3 bucket