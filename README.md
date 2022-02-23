# postgresql-rds-dbeaver

RDS setup using Terraform.
- Engine: PostgreSQL
- Connection using DBeaver
- Create a Multi-AZ setup
- Create a read-replica

### 1. Preparing the environment and VPC

As usual, `providers.tf` contains data on the cloud services provider and region, `variables.tf` has all variables from `main.tf` code declared, and `parameters.auto.tfvars` has all data to avoid hardcoding. Apart from those, an `outputs.tf` file will be necessary for credentials.

Instead of provisioning several resources depending on another top VPC resource, I decided to use a [module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) for the VPC. Thankfully, provisioning subnets is already done in this block of code.

I also set up a `data` source to pick the list of availability zones related to the region defined on the `providers.tf` file.

The database must be configured on a private subnet, for security reasons. Upon configuring the meta-arguments for private and public subnets, make sure to set the variable as list type.

```terraform
#main.tf
data "aws_availability_zones" "azs" {
  all_availability_zones = true

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = var.vpcName
  cidr = var.vpcCIDRBlock
  azs = data.aws_availability_zones.azs.names
  private_subnets = var.privSubCIDRBlocks
  public_subnets = var.pubSubCIDRBlocks
  enable_dns_hostnames = true
  enable_dns_support = true
}
```

### 2. Create subnet and security groups

To create the subnet group (that is, a collection of subnets) for the database, the `aws_db_subnet_group` is the proper resource to be used. This subnet group uses subnets created by the `ourDBVPC` module.

In our scenario, the `subnet_ids` must point to the public subnets, so we could test it using DBeaver. However, that's not good practice and it should point to private in production environments.

This resource will be used to avoid Terraform creating RDS instances on the default VPC.

```terraform
#main.tf
resource "aws_db_subnet_group" "ourDBSubGroup" {
  name = var.ourDBSubGroupName
  subnet_ids = module.vpc.public_subnets
}
```

A security group must also be provisioned:

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

### 3. Create the database instance and parameter group

To configure the RDS instance on a database-level, a parameter group is required. To create the parameter group, a specific resource must be used:

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

To create the read-replica on the next stages, the `maintenance_window`, `backup_window` and `backup_retention_period` meta-arguments must be set and the timespan declared must not overlap; to ensure multi-AZ, the `multi_az` meta-argument should be set to `true`.

```terraform
#main.tf
resource "aws_db_instance" "ourDBInst" {
  identifier = var.ourDBInstIdentifier
  instance_class = var.ourDBInstClass
  allocated_storage = 5
  engine = var.ourDBInstEngine
  engine_version = var.ourDBInstEngineV
  username = var.ourDBInstUsername
  password = var.ourDBInstPassword
  db_subnet_group_name = aws_db_subnet_group.ourDBSubGroup.name
  vpc_security_group_ids = [aws_security_group.ourDBSecG.id]
  parameter_group_name = aws_db_parameter_group.ourDBParamGroup.name
  publicly_accessible = true
  skip_final_snapshot = true
  multi_az = true
  backup_retention_period = 3
  backup_window = "03:31-05:00"
  maintenance_window = "Mon:01:00-Mon:03:30"
}
```

### 4. Authentication and output variables

The database username and password must be configured - therefore, on the `variables.tf` file, a `sensitive` meta-argument is added so that the password is hidden from the output during Terraform operations. Also, for our scenario, it's better to create an additional `secret.tfvars` file, where the database username and password will be stored:

```terraform
#variables.tf
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
```

Even so, Terraform stores the password on the `.tfstate` file. Hence why is important to add this file and `secret.tfvars` to `.gitignore` upon versioning, so such data will not be persisted, and an additional layer of security is added (thanks [@pdoerning](https://github.com/pdoerning) for the heads-up and [@tigpt](https://github.com/tigpt) for the `secret.tfvars` suggestion!).

```terraform
#.gitignore
*.terraform
*.tfstate
*.tfvars
.terraform.lock.hcl
*.git
.DS_Store
```

Outputs work similarly to return values - it returns information about the infrastructure on the standard output. An `outputs.tf` file must be created and, in our scenario, we need to have three outputs available to construct the database connection string, later: the hostname, port and username of the database instance.

```terraform
#outputs.tf
output "outHostname" {
  value = aws_db_instance.ourDBInst.address
  sensitive = true
}

output "outPort" {
  value = aws_db_instance.ourDBInst.port
  sensitive = true
}

output "outUsername" {
  value = aws_db_instance.ourDBInst.username
  sensitive = true
}
```

### 5. Creating the read-replica

In order to create the read-replica, one additional database instance resource must be provisioned, using the `replicate_source_db` meta-argument pointing to the primary database (in this scenario, the read-replica uses the ARN instead of the regular primary database identifier as value for the meta-argument, considering that this database can replicate cross-region). There is no need to provision username and password.

```terraform
#main.tf
resource "aws_db_instance" "ourDBInstRR" {
  replicate_source_db = aws_db_instance.ourDBInst.arn
  identifier = var.ourDBInstRRIdentifier
  instance_class = var.ourDBInstClass
  password = ""
  db_subnet_group_name = aws_db_subnet_group.ourDBSubGroup.name
  vpc_security_group_ids = [aws_security_group.ourDBSecG.id]
  parameter_group_name = aws_db_parameter_group.ourDBParamGroup.name
  publicly_accessible = true
  skip_final_snapshot = true
  multi_az = false
}
```

### 6. Running the database

In order to run it properly, recognizing the `.tfvars` files, the following command must be executed:

`terraform apply -var-file="secret.tfvars"`

That way, Terraform will provision the database instance and networking, with multi-AZ and read-replica set.

To use DBeaver for connection, [download it on your environment](https://dbeaver.io/download/) and, upon starting, configure it properly: select PostgreSQL and enter your environment's endpoint and port, username and password on the "Connect to a database" menu:

![Screenshot 2022-02-23 at 09 57 46](https://user-images.githubusercontent.com/22382891/155297102-c7a6b596-600f-4979-a734-50a211ef642c.png)
