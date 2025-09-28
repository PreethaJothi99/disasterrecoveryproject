# Naming & DNS
variable "project_name"       {}
variable "hosted_zone_name"   {}  # e.g., "disasterrecoveryproject.online."
variable "app_record_name"    {}  # e.g., "app.disasterrecoveryproject.online"

# VPC CIDRs
variable "primary_vpc_cidr"   {}
variable "secondary_vpc_cidr" {}

# App instances
variable "instance_type"      {}
variable "key_pair_name"      { default = null }  # optional SSH

# DB creds
variable "db_username"        {}
variable "db_password"        { sensitive = true }

# S3 replication
variable "replication_prefix" { default = "" }    # "" = replicate everything
variable "alert_email" {}

