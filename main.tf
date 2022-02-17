module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = var.vpcName
  cidr                 = var.vpcCIDRBlock
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = [var.pubSubCIDRBlock]
  public_subnets       = [var.privSubCIDRBlock]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "ourDBSubGroup" {
  name       = var.ourDBSubGroupName
  subnet_ids = module.vpc.private_subnets
}
