data "aws_iam_policy_document" "db-monitor-sts" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "db-monitor" {
  name = "AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "db-monitor" {
  description = "Role to enable Enhanced RDS Monitoring"

  assume_role_policy  = data.aws_iam_policy_document.db-monitor-sts.json
  managed_policy_arns = [data.aws_iam_policy.db-monitor.arn]

  name_prefix = "db-monitoring"
  path = join("/", [
    "",
    lookup(var.org_meta, "url"),
    lookup(var.project_meta, "short_name"),
    var.deployment_environment,
    ""
  ])
}

resource "aws_db_subnet_group" "database" {
  description = "Subnet group to host the database in"

  name = join("-", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment
    ]
  )

  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "database" {
  description = "Attach to database instance and app services"

  name_prefix = join("-", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment,
    "database"
    ]
  )

  vpc_id = var.vpc_id

  ingress {
    description = "Allow from self"
    from_port   = lookup(var.database, "port")
    to_port     = lookup(var.database, "port")
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Access to Database"
  }
}

resource "random_password" "database" {
  length  = lookup(var.database, "password_length")
  special = false
}

resource "aws_rds_cluster" "database" {
  cluster_identifier = join("-", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment
    ]
  )
  database_name   = lookup(var.database, "name")
  master_username = lookup(var.database, "admin_user")
  master_password = var.master_password != "" ? var.master_password : random_password.database.result

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = lookup(var.database, "engine_version")

  serverlessv2_scaling_configuration {
    max_capacity = lookup(var.serverless_capacity, "maximum")
    min_capacity = lookup(var.serverless_capacity, "minimum")
  }

  copy_tags_to_snapshot = true

  skip_final_snapshot = lookup(var.backup, "skip_final_snapshot")
  final_snapshot_identifier = join("-", [
    lookup(var.backup, "final_snapshot_identifier"),
    formatdate("YYYY-MM-DD-hh-mm", timestamp())
    ]
  )

  backup_retention_period = lookup(var.backup, "retention_days")

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name
  network_type           = "DUAL"

  apply_immediately   = true
  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [
      availability_zones,
      final_snapshot_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "database" {
  cluster_identifier = aws_rds_cluster.database.id
  identifier_prefix = join("-", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment
    ]
  )

  engine               = aws_rds_cluster.database.engine
  engine_version       = aws_rds_cluster.database.engine_version
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_rds_cluster.database.db_subnet_group_name
  apply_immediately    = aws_rds_cluster.database.apply_immediately

  monitoring_role_arn                   = lookup(var.monitoring, "interval_seconds") == 0 ? null : aws_iam_role.db-monitor.arn
  monitoring_interval                   = lookup(var.monitoring, "interval_seconds")
  performance_insights_enabled          = lookup(var.monitoring, "performance_insights_enabled")
  performance_insights_retention_period = lookup(var.monitoring, "performance_insights_retention_days")

  publicly_accessible = var.public_access

  /**
  lifecycle {
    prevent_destroy = var.deletion_protection
  }
  **/
}

resource "aws_secretsmanager_secret" "db-credentials" {
  description = "Database connection parameters and access credentials"

  name_prefix = join("/", [
    lookup(var.org_meta, "url"),
    lookup(var.project_meta, "short_name"),
    var.deployment_environment,
    "database"
    ]
  )
}

resource "aws_secretsmanager_secret_version" "db-credentials" {
  secret_id = aws_secretsmanager_secret.db-credentials.id
  secret_string = jsonencode(
    zipmap(
      [
        "dbinstanceidentifier",
        "dbname",
        "engine",
        "host",
        "port",
        "username",
        "password"
      ],
      [
        aws_rds_cluster.database.id,
        aws_rds_cluster.database.database_name,
        aws_rds_cluster.database.engine,
        aws_rds_cluster.database.endpoint,
        aws_rds_cluster.database.port,
        aws_rds_cluster.database.master_username,
        aws_rds_cluster.database.master_password
      ]
    )
  )
}
