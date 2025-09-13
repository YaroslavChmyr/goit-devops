variable "use_aurora" {
  description = "Whether to create Aurora cluster or regular RDS instance"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "engine" {
  description = "Database engine (mysql, postgres, etc.)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "Instance class for RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp2"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Aurora specific variables
variable "aurora_cluster_identifier" {
  description = "Aurora cluster identifier"
  type        = string
  default     = null
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r5.large"
}

variable "aurora_instances_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "aurora_auto_pause" {
  description = "Enable auto pause for Aurora serverless"
  type        = bool
  default     = false
}

variable "aurora_auto_pause_seconds" {
  description = "Auto pause seconds for Aurora serverless"
  type        = number
  default     = 300
}

variable "aurora_min_capacity" {
  description = "Minimum capacity for Aurora serverless"
  type        = number
  default     = 2
}

variable "aurora_max_capacity" {
  description = "Maximum capacity for Aurora serverless"
  type        = number
  default     = 16
}
