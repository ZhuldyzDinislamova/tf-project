resource "aws_lb" "alb" {
  name               = "project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_sg
  subnets            = var.alb_subnets

  tags = {
    Name = "project_alb"
  }
}

# adding port80 listener to alb:
resource "aws_lb_listener" "http_listenter" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on = [aws_lb_listener.https_listener]

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# adding port443 listener to alb:
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert_arn
  depends_on = [aws_lb.alb]

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}

