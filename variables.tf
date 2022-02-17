variable "region" {
  type = string
  description = "Region where all resources will be provisioned"
}

variable "vpcCIDRBlock" {
  type = string
  description = "CIDR Block for the VPC"
}

variable "pubSubCIDRBlock" {
  type = string
  description = "CIDR Block for the public subnet"
}

variable "privSubCIDRBlock" {
  type = string
  description = "CIDR Block for the private subnet"
}
