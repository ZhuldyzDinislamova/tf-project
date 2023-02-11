resource "aws_security_group" "security_group" {
  name   = var.sg_name
  vpc_id = var.vpc_id

  tags = {
    Name = var.sg_name
  }
}

resource "aws_security_group_rule" "rule" {
  count             = length(var.rules)
  type              = element(var.rules[count.index], 0)
  cidr_blocks              = length(element(var.rules[count.index], 1)) <= 18 ? [element(var.rules[count.index], 1)] : null
  source_security_group_id = startswith(element(var.rules[count.index], 1), "sg-") ? element(var.rules[count.index], 1) : null
  from_port         = element(var.rules[count.index], 2)
  to_port           = element(var.rules[count.index], 3)
  protocol          = element(var.rules[count.index], 4)
  description       = element(var.rules[count.index], 5)
  security_group_id = aws_security_group.security_group.id
}