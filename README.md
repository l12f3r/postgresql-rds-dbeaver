# postgresql-rds-dbeaver

RDS setup using Terraform.
- Engine: PostgreSQL
- Connection using DBeaver

- Database defined within the AWS environment from the [Bastion Host](https://github.com/l12f3r/terraform-bastion-host) exercise
- Create a Multi-AZ setup
- Create a read-replica

### 1. Preparing the environment

First, use a module for the VPC. The DB must be configured on a private subnet, though.

https://learn.hashicorp.com/tutorials/terraform/aws-rds?in=terraform/modules&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS
