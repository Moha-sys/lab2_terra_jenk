variable "aws_region" {
  type        = string
  description = "AWS region for the provider"
  default     = "us-east-1"
}

variable "floci_endpoint" {
  type        = string
  description = "Floci emulator endpoint URL"
  default     = "http://localhost:4566"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (dev, stg, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name tag for the VPC"
  default     = "main-vpc"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS resolution support in the VPC"
  default     = true
}

