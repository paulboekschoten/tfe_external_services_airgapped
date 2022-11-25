variable "region" {
  type        = string
  description = "The region to deploy resources in."
}

variable "enviroment_name" {
  type        = string
  description = "Name used to create and tag resources."
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range for the VPC in CIDR format."
}