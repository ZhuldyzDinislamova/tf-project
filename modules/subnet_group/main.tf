resource "aws_db_subnet_group" "subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = var.subnet_id

  tags = {
    Name = "db_subnet_group"
  }
}