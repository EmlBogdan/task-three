resource "aws_security_group" "ollama_alb_sg" {
  name        = "ollama_alb_sg"
  description = "Security group for alb"
  vpc_id      = aws_vpc.main_vpc.id
  tags = {
    Name = "ollama_alb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_ollama" {
  security_group_id = aws_security_group.ollama_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 11434
  ip_protocol       = "tcp"
  to_port           = 11434
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_webui" {
  security_group_id = aws_security_group.ollama_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_grafana" {
  security_group_id = aws_security_group.ollama_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_prometheus" {
  security_group_id = aws_security_group.ollama_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9090
  ip_protocol       = "tcp"
  to_port           = 9090
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outcoming_traffic_ipv4" {
  security_group_id = aws_security_group.ollama_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "ollama_alb" {
  name                 = "ollama-alb"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.ollama_alb_sg.id]
  subnets              = [for subnet in aws_subnet.public_subnets : subnet.id]
  preserve_host_header = true
}

resource "aws_lb_target_group" "llm_tg" {
  name        = "webui-tg-t-one-ollama"
  port        = 11434
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
  }
}

resource "aws_lb_listener" "ollama_listener" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = 11434
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm_tg.arn
  }
}


resource "aws_lb_target_group" "webui_tg" {
  name        = "webui-tg-t-one"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
  }
}

resource "aws_lb_listener" "webui_listener" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webui_tg.arn
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg-t-one"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
  }
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_lb_target_group" "prometheus_tg" {
  name        = "prometheus-tg-t-one"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
  }
}

resource "aws_lb_listener" "prometheus_listener" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = 9090
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}
