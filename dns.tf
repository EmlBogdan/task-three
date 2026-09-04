data "aws_acm_certificate" "domain_cert" {
  domain   = "universal-domain.online"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "http_listener_redirect" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.ollama_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.domain_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad gateway"
      status_code  = "404"
    }
  }
}


resource "aws_lb_listener_rule" "grafana_listener_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    host_header {
      values = ["grafana.universal-domain.online"]
    }
  }

  condition {
    source_ip {
      values = [var.my_ip, "10.0.0.0/16"]
    }
  }
}

resource "aws_lb_listener_rule" "webui_listener_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webui_tg.arn
  }

  condition {
    host_header {
      values = ["universal-domain.online"]
    }
  }
}

resource "aws_lb_listener_rule" "prometheus_listener_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 40
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }

  condition {
    host_header {
      values = ["prometheus.universal-domain.online"]
    }
  }

  condition {
    source_ip {
      values = [var.my_ip, "10.0.0.0/16"]
    }
  }
}



data "aws_route53_zone" "ollama_zone" {
  name         = "universal-domain.online"
  private_zone = false
}

resource "aws_route53_record" "subdomains" {
  for_each = toset(["grafana", "prometheus"])
  zone_id  = data.aws_route53_zone.ollama_zone.id
  name     = "${each.key}.${data.aws_route53_zone.ollama_zone.name}"
  type     = "A"

  alias {
    name                   = aws_lb.ollama_alb.dns_name
    zone_id                = aws_lb.ollama_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "webui_record" {
  zone_id = data.aws_route53_zone.ollama_zone.id
  name    = data.aws_route53_zone.ollama_zone.name
  type    = "A"

  alias {
    name                   = aws_lb.ollama_alb.dns_name
    zone_id                = aws_lb.ollama_alb.zone_id
    evaluate_target_health = true
  }
}
