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

resource "aws_security_group" "ourDBSecG" {
  name   = var.ourDBSecGName
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "ourDBParamGroup" {
  name   = var.ourDBParamGroupName
  family = var.ourDBParamGroupFamily

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "ourDBInst" {
  identifier             = var.ourDBInstIdentifier
  instance_class         = var.ourDBInstClass
  allocated_storage      = 5
  engine                 = var.ourDBInstEngine
  engine_version         = var.ourDBInstEngineV
  username               = var.ourDBInstUsername
  password               = var.ourDBInstPassword
  db_subnet_group_name   = aws_db_subnet_group.ourDBSubGroup.name
  vpc_security_group_ids = [aws_security_group.ourDBSecG.id]
  parameter_group_name   = aws_db_parameter_group.ourDBParamGroup.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
