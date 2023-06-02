# Introduction

This terraform module helps launch a single AWS Aurora Serverless v2 PostgreSQL Cluster. The following AWS Resources are created

## Resources created

1. An AWS Aurora Serverless v2 PostgreSQL cluster - the star of the show.
2. A subnet group - composed of private subnets and containing the RDS cluster
3. A security group - that can be attached to other resources to give them access to the database
4. An entry in AWS Secrets Manager - holding database connection credentials
5. IAM Role - to allow RDS cluster to utilise Enhanced Monitoring features
5. Database master password - automatically generated 

:warning: Please note that the auto-generated password is not a high-entropy password. You can supply your own password if you wish.

## How to use

:warning: Please note that this module compatible with AWS provider version >= 5.0.0. Tested with v5.1.0;

1. Import the module in your root module:

```
module "database" {
  source = "git::https://gitlab.com/eternaltyro/terraform-aws-rds.git"
  ...
  key = var.value
}
```

If you wish to use SSH to connect to git, then something like this will help:

```
module "vpc" {
  source = "git::ssh://username@gitlab.com/eternaltyro/terraform-aws-rds.git"
  ...
  key = var.value
}
```

2. Write a provider block with the official AWS provider:

```
terraform {
  required_version = ">= 1.4.0"

  requried_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "aws" {
  region = lookup(var.aws_region, var.deployment_environment)

  default_tags {
    tags = var.resource_tags
  }
}

provider "random" {}
```

3. Initialise the backend, and plan

```
$ terraform init
$ terraform plan
```
## Outputs

1. `rds_cluster_id` - ID of the RDS cluster itself (NOT the contained instance)
2. `subnet_group_id` - ID of the subnet group containing the RDS cluster instance
3. `database_security_group_id` - Security group ID of the database; Attach this one to your app services to gain access to the DB.
4. `database_credentials` - ARN of the AWS Secrets Manager entry containing the DB connection credentials.
5. `database_connection_host` - Hostname of the database to connect to
6. `database_connection_port` - TCP Port of the database to connect to
7. `database_name` - Database name to connect to
8. `database_connection_user` - Username of the database to connect to

## Variables

- `org_meta` - A map of organisation metadata containing org name, short name and url; Defaults are set but empty.
- `project_meta` - A map of project metadata containing project name, short name, version string and url. Defaults are set but empty
- `deployment_environment` - Deployment environment or flavour; Used for names; Defaults are not set.
- `vpc_id` - ID of the VPC in which to host resources; Usually obtained from the vpc module.
- `subnet_ids` - A list of private subnets with which to build the subnet group containing the RDS cluster
- `database` - A map of database connection parameters
- `backup` - A map of backup configuration
- `serverless_capacity` - A map of minimum and maximum APU units to launch the DB cluster with.
- `deletion_protection` - A boolean value indicating whether the RDS cluster must be protected against accidental deletion; false by default
- `publicly_accessible` - A boolean flag for whether the database should be publicly accessible; false by default
- `default_tags` - A map of default key-value strings used as resource tags
- `master_password` - password string supplied by admins; This will be used over auto-generated password. If omitted, auto-generated password will be used.

## References

- None.

## Copyright and License texts

The project is licensed under GNU LGPL. Please make any modifications to this module public. Read LICENSE, COPYING.LESSER, and COPYING files for license text

Copyright (C) 2023 eternaltyro
This file is part of Terraform AWS RDS Module aka terraform-aws-rds project

terraform-aws-rds is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License.

terraform-aws-rds is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

License text can be found in the repository
