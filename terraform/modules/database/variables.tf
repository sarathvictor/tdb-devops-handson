variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "app_security_group_id" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type = string
  sensitive = true
  ephemeral = true
}
variable "db_instance_class" { type = string }
variable "multi_az" { type = bool }
