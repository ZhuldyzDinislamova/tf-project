resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = try(var.gateway_id, null) # public rtb
    nat_gateway_id = try(var.nat_gateway_id, null) # private rtb
  }

  tags = {
    Name = "${var.gateway_id != null ? "public" : "private"}_route_table"
  }
}

# associate subnets with this route table:
resource "aws_route_table_association" "rtb-association" {
  count          = length(var.subnet_ids)
  route_table_id = aws_route_table.route_table.id
  subnet_id      = var.subnet_ids[count.index]
}