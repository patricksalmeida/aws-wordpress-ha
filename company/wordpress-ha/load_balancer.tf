resource "aws_security_group" "wp_alb_sg" {
  name   = "${var.name}-${var.environment}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP request from anywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS request from anywhere"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-${var.environment}-alb-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_lb" "wp_alb" {
  name               = "${var.name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wp_alb_sg.id]

  subnets = var.cluster.public_subnets

  enable_deletion_protection = false

  tags = {
    Name        = "${var.name}-${var.environment}-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "wp_alb_tg" {
  name     = "${var.name}-${var.environment}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    timeout             = "5"
    interval            = "30"
    matcher             = "200"
    path                = "/wp-admin"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${var.name}-${var.environment}-alb-tg"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener" "wp_alb_http_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_alb_tg.arn
  }

  tags = {
    Name        = "${var.name}-${var.environment}-alb-http-listner"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener" "wp_alb_https_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.wp_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_alb_tg.arn
  }

  tags = {
    Name        = "${var.name}-${var.environment}-alb-https-listner"
    Environment = "${var.environment}"
  }
}
