# Variables for n8n Banking Infrastructure

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition = contains([
      "us-east-1", "us-west-2", "eu-west-1", "eu-central-1"
    ], var.aws_region)
    error_message = "AWS region must be one of the approved banking regions."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, uat, production)"
  type        = string

  validation {
    condition = contains([
      "dev", "staging", "uat", "production"
    ], var.environment)
    error_message = "Environment must be one of: dev, staging, uat, production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition = contains([
      "1.27", "1.28", "1.29"
    ], var.kubernetes_version)
    error_message = "Kubernetes version must be supported by AWS EKS."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the infrastructure"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "domain_name" {
  description = "Domain name for the n8n application"
  type        = string
  default     = "n8n.banking.internal"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9\\-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9\\-]{0,61}[a-z0-9])?)*$", var.domain_name))
    error_message = "Domain name must be a valid DNS name."
  }
}

variable "external_id" {
  description = "External ID for secure role assumption"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.external_id) >= 8
    error_message = "External ID must be at least 8 characters long."
  }
}

# Banking-specific variables
variable "compliance_frameworks" {
  description = "List of compliance frameworks to implement"
  type        = list(string)
  default     = ["PCI-DSS", "SOX", "ISO-27001"]

  validation {
    condition = alltrue([
      for framework in var.compliance_frameworks :
      contains(["PCI-DSS", "SOX", "ISO-27001", "GDPR", "CCPA"], framework)
    ])
    error_message = "Compliance frameworks must be from the approved list."
  }
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "confidential"

  validation {
    condition = contains([
      "public", "internal", "confidential", "restricted"
    ], var.data_classification)
    error_message = "Data classification must be: public, internal, confidential, or restricted."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

variable "monitoring_enabled" {
  description = "Enable enhanced monitoring and logging"
  type        = bool
  default     = true
}

variable "encryption_at_rest" {
  description = "Enable encryption at rest for all storage"
  type        = bool
  default     = true
}

variable "encryption_in_transit" {
  description = "Enable encryption in transit for all communications"
  type        = bool
  default     = true
}

# Performance and scaling variables
variable "min_nodes" {
  description = "Minimum number of nodes in the EKS cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.min_nodes >= 3
    error_message = "Minimum nodes must be at least 3 for high availability."
  }
}

variable "max_nodes" {
  description = "Maximum number of nodes in the EKS cluster"
  type        = number
  default     = 10

  validation {
    condition     = var.max_nodes >= var.min_nodes
    error_message = "Maximum nodes must be greater than or equal to minimum nodes."
  }
}

variable "node_instance_types" {
  description = "List of instance types for EKS worker nodes"
  type        = list(string)
  default     = ["m6i.large", "m6i.xlarge", "m6i.2xlarge"]

  validation {
    condition = alltrue([
      for instance_type in var.node_instance_types :
      can(regex("^[a-z][0-9][a-z]?\\.[a-z0-9]+$", instance_type))
    ])
    error_message = "Instance types must be valid AWS instance types."
  }
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class for the database"
  type        = string
  default     = "db.r6g.large"

  validation {
    condition = contains([
      "db.r6g.large", "db.r6g.xlarge", "db.r6g.2xlarge",
      "db.r6g.4xlarge", "db.r6g.8xlarge", "db.r6g.12xlarge"
    ], var.db_instance_class)
    error_message = "Database instance class must be from the approved list."
  }
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 100

  validation {
    condition     = var.db_allocated_storage >= 100 && var.db_allocated_storage <= 10000
    error_message = "Database storage must be between 100 and 10000 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 1000

  validation {
    condition     = var.db_max_allocated_storage >= var.db_allocated_storage
    error_message = "Maximum database storage must be greater than or equal to allocated storage."
  }
}

# Security variables
variable "enable_waf" {
  description = "Enable AWS WAF for application protection"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced for DDoS protection"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail for audit logging"
  type        = bool
  default     = true
}

# Networking variables
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention period for VPC Flow Logs (days)"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.flow_log_retention_days)
    error_message = "Flow log retention days must be a valid CloudWatch Logs retention period."
  }
}

# Cost optimization variables
variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_instance_percentage" {
  description = "Percentage of spot instances in the node group"
  type        = number
  default     = 0

  validation {
    condition     = var.spot_instance_percentage >= 0 && var.spot_instance_percentage <= 100
    error_message = "Spot instance percentage must be between 0 and 100."
  }
}

# Disaster recovery variables
variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_region" {
  description = "AWS region for cross-region backup"
  type        = string
  default     = "us-west-2"

  validation {
    condition = contains([
      "us-east-1", "us-west-2", "eu-west-1", "eu-central-1"
    ], var.backup_region)
    error_message = "Backup region must be one of the approved banking regions."
  }
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}