variable "region" {
  type        = string
  description = "The region to deploy resources in."
}

variable "environment_name" {
  type        = string
  description = "Name used to create and tag resources."
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range for the VPC in CIDR format."
}

variable "ssh_port" {
  description = "Server port for SSH requests."
  type        = number
  default     = 22
}

variable "https_port" {
  description = "Server port for HTTPS requests."
  type        = number
  default     = 443
}

variable "replicated_port" {
  description = "Server port for Replicated dashboard."
  type        = number
  default     = 8800
}

variable "postgresql_port" {
  description = "PostgreSQL database port."
  type        = number
  default     = 5432
}

variable "instance_type" {
  description = "The instance type to use for the TFE host."
  type        = string
  default     = "m5.xlarge"
}

variable "route53_zone" {
  description = "The domain used in the URL."
  type        = string
}

variable "route53_subdomain" {
  description = "the subdomain of the url"
  type        = string
}

variable "cert_email" {
  description = "Email address used to obtain ssl certificate."
  type        = string
}

variable "postgresql_password" {
  description = "PostgreSQL password."
  type        = string
}

variable "tfe_encryption_password" {
  description = "Password used to encrypt TFE data."
  type        = string
}

variable "replicated_password" {
  description = "Replicated dahsboard password."
  type        = string
}

variable "admin_username" {
  description = "Username for the TFE admin account."
  type        = string
}

variable "admin_email" {
  description = "Email address for the TFE admin account."
  type        = string
}

variable "admin_password" {
  description = "Password for the TFE admin account."
  type        = string
}

variable "airgap_file" {
  description = "Name of the airgap file in folder files/"
  type        = string
}