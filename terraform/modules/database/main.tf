resource "aws_db_subnet_group" "this" {
  name = "booking-${var.environment}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags = { Name = "booking-${var.environment}-db-subnets" }
}
resource "aws_security_group" "database" {
  name = "booking-${var.environment}-db-sg"
  description = "Allow PostgreSQL only from application security group."
  vpc_id = var.vpc_id
  ingress {
    description = "PostgreSQL from application resources only"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [var.app_security_group_id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "booking-${var.environment}-db-sg" }
}
resource "aws_db_instance" "this" {
  identifier = "booking-${var.environment}-postgres"
  engine = "postgres"
  engine_version = "16.4"
  instance_class = var.db_instance_class
  allocated_storage = 20
  max_allocated_storage = 100
  storage_type = "gp3"
  storage_encrypted = true
  db_name = "bookings"
  username = var.db_username
  password = var.db_password
  port = 5432
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible = false
  multi_az = var.multi_az
  backup_retention_period = var.environment == "prod" ? 14 : 1
  deletion_protection = var.environment == "prod"
  auto_minor_version_upgrade = true
  apply_immediately = false
  skip_final_snapshot = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "booking-prod-final-snapshot" : null
  tags = { Name = "booking-${var.environment}-postgres" }
  lifecycle {
    prevent_destroy = true
  }
}
