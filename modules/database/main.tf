resource "aws_db_instance" "db" {
  allocated_storage           = var.allocated_storage
  engine                      = var.engine 
  engine_version              = var.engine_version 
  instance_class              = var.instance_class 
  db_name                     = var.db_name
  username                    = var.username
  password                    = var.password
  vpc_security_group_ids      = var.db_security_group_id
  db_subnet_group_name        = var.db_subnet_group_name
  multi_az                    = var.multi_az 
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  skip_final_snapshot         = var.skip_final_snapshot
}

