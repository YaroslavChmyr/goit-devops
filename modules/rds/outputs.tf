# Common outputs
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.rds.arn
}

# RDS Instance outputs
output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].arn
}

output "rds_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].endpoint
}

output "rds_instance_address" {
  description = "Address of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].address
}

output "rds_instance_port" {
  description = "Port of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].port
}

output "rds_instance_engine" {
  description = "Engine of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].engine
}

output "rds_instance_engine_version" {
  description = "Engine version of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].engine_version
}

# Aurora Cluster outputs
output "aurora_cluster_id" {
  description = "ID of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].id : null
}

output "aurora_cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].arn : null
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : null
}

output "aurora_cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "aurora_cluster_port" {
  description = "Port of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].port : null
}

output "aurora_cluster_engine" {
  description = "Engine of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].engine : null
}

output "aurora_cluster_engine_version" {
  description = "Engine version of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].engine_version : null
}

output "aurora_cluster_instances" {
  description = "List of Aurora cluster instance IDs"
  value       = var.use_aurora ? aws_rds_cluster_instance.main[*].id : []
}

# Universal outputs (works for both RDS and Aurora)
output "database_endpoint" {
  description = "Database endpoint (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].endpoint
}

output "database_port" {
  description = "Database port (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].port : aws_db_instance.main[0].port
}

output "database_engine" {
  description = "Database engine (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].engine : aws_db_instance.main[0].engine
}

output "database_name" {
  description = "Database name"
  value       = var.db_name
}

output "is_aurora" {
  description = "Whether this is an Aurora cluster"
  value       = var.use_aurora
}
