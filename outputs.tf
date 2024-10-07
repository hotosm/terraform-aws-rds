output "rds_cluster_id" {
  value = aws_rds_cluster.database.id
}

output "subnet_group_id" {
  value = aws_db_subnet_group.database.id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}

output "database_credentials" {
  value = aws_secretsmanager_secret_version.db-credentials.arn
}

output "database_connection_host" {
  value = aws_rds_cluster.database.endpoint
}

output "database_connection_port" {
  value = aws_rds_cluster.database.port
}

output "database_name" {
  value = aws_rds_cluster.database.database_name
}

output "database_connection_user" {
  value = aws_rds_cluster.database.master_username
}

output "database_config_as_ecs_inputs" {
  description = "This is to easily merge with ECS module"
  value = {
      POSTGRES_USER = aws_rds_cluster.database.master_username
      POSTGRES_ENDPOINT = aws_rds_cluster.database.endpoint
      POSTGRES_DB = aws_rds_cluster.database.database_name
      POSTGRES_PORT = aws_rds_cluster.database.port
  }
}

output "database_config_as_ecs_secrets_inputs" {
  description = "This is to easily merge with ECS module"
  value = [
        {
            name      = "POSTGRES_PASSWORD"
            valueFrom = aws_secretsmanager_secret_version.db-credentials-password.arn
        }
    ]
}