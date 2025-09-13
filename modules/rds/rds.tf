# Regular RDS Instance
resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  identifier = var.db_name

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.master_username
  password = var.master_password

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Parameter group
  parameter_group_name = var.engine == "postgres" ? aws_db_parameter_group.postgres[0].name : aws_db_parameter_group.mysql[0].name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # High availability
  multi_az = var.multi_az

  # Snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring[0].arn

  tags = merge(var.tags, {
    Name = var.db_name
  })

  depends_on = [aws_db_subnet_group.main, aws_security_group.rds]
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.use_aurora ? 0 : 1
  name  = "${var.db_name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.db_name}-rds-enhanced-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.use_aurora ? 0 : 1
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
