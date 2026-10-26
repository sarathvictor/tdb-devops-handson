variable "aws_region" {
  type = string
  description = "AWS region."
  default = "ap-south-1"
}
variable "environment" {
  type = string
  description = "Environment name."
  default = "dev"
  validation {
    condition = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}
variable "vpc_cidr" {
  type = string
  description = "VPC IPv4 CIDR."
  default = "10.40.0.0/16"
}
variable "db_username" {
  type = string
  description = "PostgreSQL master username."
  default = "booking_admin"
}
variable "db_password" {
  type = string
  description = "Inject securely; never commit this value."
  sensitive = true
  ephemeral = true
}
variable "db_instance_class" {
  type = string
  description = "RDS instance class."
  default = "db.t3.micro"
}
