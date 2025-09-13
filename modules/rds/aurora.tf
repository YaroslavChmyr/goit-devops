# Aurora Cluster
resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.aurora_cluster_identifier != null ? var.aurora_cluster_identifier : "${var.db_name}-cluster"

  # Engine configuration
  engine         = var.engine == "postgres" ? "aurora-postgresql" : "aurora-mysql"
  engine_version = var.engine == "postgres" ? "15.4" : "8.0.mysql_aurora.3.02.0"
  engine_mode    = "provisioned"

  # Database configuration
  database_name   = var.db_name
  master_username = var.master_username
  master_password = var.master_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Parameter group
  db_cluster_parameter_group_name = var.engine == "postgres" ? aws_rds_cluster_parameter_group.aurora_postgres[0].name : aws_rds_cluster_parameter_group.aurora_mysql[0].name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  # Protection
  deletion_protection = var.deletion_protection

  # Storage
  storage_encrypted = true

  # Serverless configuration (if auto_pause is enabled)
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.aurora_auto_pause ? [1] : []
    content {
      max_capacity = var.aurora_max_capacity
      min_capacity = var.aurora_min_capacity
    }
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-cluster"
  })

  depends_on = [aws_db_subnet_group.main, aws_security_group.rds]
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "main" {
  count = var.use_aurora ? var.aurora_instances_count : 0

  identifier         = "${var.db_name}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.aurora_enhanced_monitoring[0].arn

  tags = merge(var.tags, {
    Name = "${var.db_name}-${count.index + 1}"
  })

  depends_on = [aws_rds_cluster.main]
}

# IAM Role for Aurora Enhanced Monitoring
resource "aws_iam_role" "aurora_enhanced_monitoring" {
  count = var.use_aurora ? 1 : 0
  name  = "${var.db_name}-aurora-enhanced-monitoring"

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
    Name = "${var.db_name}-aurora-enhanced-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "aurora_enhanced_monitoring" {
  count      = var.use_aurora ? 1 : 0
  role       = aws_iam_role.aurora_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
