output "vpc_id" {
  value = module.network.vpc_id
}
output "database_endpoint" {
  description = "Private RDS endpoint hostname:port."
  value = module.database.endpoint
}
