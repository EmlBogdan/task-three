output "postgres_endpoint" {
  description = "PostgreSQL connection endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_username" {
  description = "PostgreSQL connection endpoint"
  value       = aws_db_instance.postgres.username
}
