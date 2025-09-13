# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.db_name}-subnet-group"
  })
}

# Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.db_name}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Parameter Group for PostgreSQL
resource "aws_db_parameter_group" "postgres" {
  count  = var.engine == "postgres" ? 1 : 0
  family = "postgres15"
  name   = "${var.db_name}-postgres-params"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "work_mem"
    value = "4MB"
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-postgres-params"
  })
}

# Parameter Group for MySQL
resource "aws_db_parameter_group" "mysql" {
  count  = var.engine == "mysql" ? 1 : 0
  family = "mysql8.0"
  name   = "${var.db_name}-mysql-params"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-mysql-params"
  })
}

# Parameter Group for Aurora PostgreSQL
resource "aws_rds_cluster_parameter_group" "aurora_postgres" {
  count  = var.use_aurora && var.engine == "postgres" ? 1 : 0
  family = "aurora-postgresql15"
  name   = "${var.db_name}-aurora-postgres-params"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "work_mem"
    value = "4MB"
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-aurora-postgres-params"
  })
}

# Parameter Group for Aurora MySQL
resource "aws_rds_cluster_parameter_group" "aurora_mysql" {
  count  = var.use_aurora && var.engine == "mysql" ? 1 : 0
  family = "aurora-mysql8.0"
  name   = "${var.db_name}-aurora-mysql-params"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-aurora-mysql-params"
  })
}
