# postgresql-rds-dbeaver

RDS setup using Terraform.
- Engine: PostgreSQL
- Connection using DBeaver

- Database defined within the AWS environment from the [Bastion Host](https://github.com/l12f3r/terraform-bastion-host) exercise
- Create a Multi-AZ setup
- Create a read-replica

### 1. Preparing the environment

As usual, `providers.tf` contains data on the cloud service provider, `variables.tf` has all variables from `main.tf` code declared, and `parameters.auto.tfvars` has all data to avoid hardcoding.

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

https://learn.hashicorp.com/tutorials/terraform/aws-rds?in=terraform/modules&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS
