variable "region" {
  type = string
  description = "Region where all resources will be provisioned"
}

variable "vpcName" {
  type = string
  description = "Nametag for the VPC"
}

variable "vpcCIDRBlock" {
  type = string
  description = "CIDR Block for the VPC"
}

variable "pubSubCIDRBlocks" {
  type = list(string)
  description = "CIDR Block for the public subnet"
}

variable "privSubCIDRBlocks" {
  type = list(string)
  description = "CIDR Block for the private subnet"
}

variable "ourDBSubGroupName" {
  type = string
  description = "Nametag for the database subnet group"
}

variable "ourDBSecGName" {
  type = string
  description = "Nametag for the database security group"
}

variable "ourDBParamGroupName" {
  type = string
  description = "Nametag for the database parameter group"
}

variable "ourDBParamGroupFamily" {
  type = string
  description = "Family for the database parameter group"
}

variable "ourDBInstIdentifier" {
  type = string
  description = "Identifier for the database instance"
}

variable "ourDBInstClass" {
  type = string
  description = "Instance class for the database instance"
}

variable "ourDBInstEngine" {
  type = string
  description = "Engine for the database instance"
}

variable "ourDBInstEngineV" {
  type = string
  description = "Engine version for the database instance"
}

variable "ourDBInstUsername" {
  type = string
  description = "Username credential for the database instance"
  sensitive = true
}

variable "ourDBInstPassword" {
  type = string
  description = "Password credential for the database instance"
  sensitive = true
}

variable "ourDBInstRRIdentifier" {
  type = string
  description = "Identifier for the database instance"
}
