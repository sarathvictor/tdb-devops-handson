module "network" {
  source = "../../modules/network"
  environment = var.environment
  vpc_cidr = var.vpc_cidr
}
module "database" {
  source = "../../modules/database"
  environment = var.environment
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  app_security_group_id = module.network.app_security_group_id
  db_username = var.db_username
  db_password = var.db_password
  db_instance_class = var.db_instance_class
  multi_az = true
}
