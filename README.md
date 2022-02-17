# postgresql-rds-dbeaver

RDS setup using Terraform.
- Engine: PostgreSQL
- Connection using DBeaver
- Create a Multi-AZ setup
- Create a read-replica

### 1. Preparing the environment and VPC

As usual, `providers.tf` contains data on the cloud services provider and region, `variables.tf` has all variables from `main.tf` code declared, and `parameters.auto.tfvars` has all data to avoid hardcoding. Apart from those, an `outputs.tf` file will be necessary for credentials.

Instead of provisioning several resources depending on another top VPC resource, I decided to use a module for the VPC. Thankfully, provisioning subnets is already done in this block of code.

The database must be configured on a private subnet, for security reasons.

```terraform
#main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "ourDBvpc"
  cidr                 = var.vpcCIDRBlock
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = [var.pubSubCIDRBlock]
  public_subnets       = [var.privSubCIDRBlock]
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

### 2. Create subnet and security groups

To create the subnet group (that is, a collection of subnets) for the database, the `aws_db_subnet_group` is the proper resource to be used. This subnet group uses subnets created by the `ourDBVPC` module.

This resource will be used to avoid Terraform creating RDS instances on the default VPC.

```terraform
#main.tf
resource "aws_db_subnet_group" "ourDBSubGroup" {
  name       = var.ourDBSubGroupName
  subnet_ids = module.vpc.private_subnets
}
```

A security groups must also be provisioned:

```terraform
#main.tf
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
```

### 4. Create the database instance and parameter group

To create the parameter group, a specific resource must be used:

```terraform
#main.tf
resource "aws_db_parameter_group" "ourDBParamGroup" {
  name   = var.ourDBParamGroupName
  family = var.ourDBParamGroupFamily

  parameter {
    name  = "log_connections"
    value = "1"
  }
}
```

The database instance uses the `aws_db_instance` resource. Since that I will use PostgreSQL as engine, this value is stored on the `ourDBInstEngine` variable.

```terraform
#main.tf
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
```


https://learn.hashicorp.com/tutorials/terraform/aws-rds?in=terraform/modules&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS
