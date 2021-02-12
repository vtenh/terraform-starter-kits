resource "aws_lb" "main" {
  name                       = var.name
  load_balancer_type         = "application"
  security_groups            = var.security_group_ids
  enable_deletion_protection = true
  subnets                    = var.subnet_ids
  internal                   = false
  tags                       = var.default_tags
}

resource "aws_alb_target_group" "main" {
  name        = var.name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 30
    interval            = 180
    matcher             = "200"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = var.container_port
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.main]

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn
  depends_on        = [aws_alb_target_group.main]

  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "redirect_non_www" {
  priority     = 10
  listener_arn = aws_alb_listener.https.arn

  action {
    type = "redirect"

    redirect {
      host        = "www.${var.domain_name}"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"

    }
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}
