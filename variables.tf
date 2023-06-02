variable "org_meta" {
  description = "Organisation domain and top level domain"
  type        = map(string)

  default = {
    name       = ""
    short_name = ""
    url        = ""
  }
}

variable "project_meta" {
  description = "Metadata relating to the project for which the database is being created"
  type        = map(string)

  default = {
    name       = ""
    short_name = ""
    version    = ""
    url        = ""
  }
}

variable "deployment_environment" {
  description = "Deployment flavour or variant identified by this name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which to host resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs - preferably private subnets - in which to host the RDS instance"
  type        = list(string)
}

variable "master_password" {
  description = "Master password supplied by the administrator; If set, this will be used over auto-generated password"
  type        = string
  sensitive   = true

  default = ""
}

// NOTE: Password is generated automatically and stored in AWS Secrets Manager
variable "database" {
  description = "PostgreSQL connection parameters and version."
  type        = map(string)

  default = {
    name            = ""
    admin_user      = ""
    password_length = 48
    engine_version  = 13
    port            = 5432
  }
}

variable "serverless_capacity" {
  description = "Minimum and maximum APU to assign to the RDS cluster"
  type        = map(number)

  default = {
    minimum = 0.5
    maximum = 16
  }
}

variable "deletion_protection" {
  description = "Should the RDS cluster be protected against accidental deletion?"
  type        = bool

  default = false
}

variable "storage" {
  description = "Storage parameters"
  type        = map(string)

  default = {
    type            = "gp2"
    min_capacity    = "1000"
    max_capacity    = "5000"
    throughput_MBps = "125"
    iops            = "3000"
  }
}

variable "backup" {
  description = "Database backups and snapshots"
  type        = map(string)

  default = {
    retention_days            = 7
    skip_final_snapshot       = true
    final_snapshot_identifier = ""
  }
}

variable "monitoring" {
  description = "Database monitoring and logging"
  type        = map(string)

  default = {
    interval_sec                 = 0
    performance_insights_enabled = true
  }

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], lookup(var.monitoring, "interval_sec"))
    error_message = "Monitoring interval value is invalid"
  }
}

variable "publicly_accessible" {
  description = "Should the database be publicly accessible?"
  type        = bool

  default = false
}

variable "default_tags" {
  description = "Default resource tags to apply to AWS resources"
  type        = map(string)

  default = {
    project        = ""
    maintainer     = ""
    documentation  = ""
    cost_center    = ""
    IaC_Management = "Terraform"
  }
}

