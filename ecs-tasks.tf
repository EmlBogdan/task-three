resource "aws_ecs_service" "webui-service" {
  name            = "webui"
  cluster         = aws_ecs_cluster.ollama-cluster.id
  task_definition = aws_ecs_task_definition.webui_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.webui_tg.arn
    container_name   = "webui-container"
    container_port   = 8080
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.allow_ecs_webui.id]
    subnets          = [for subnet in aws_subnet.application_subnets : subnet.id]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_ecs_task_definition.webui_task_definition]
}

resource "aws_security_group" "allow_ecs_webui" {
  name        = "allow_webui"
  description = "allow_webui inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_webui"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_webui" {
  security_group_id = aws_security_group.allow_ecs_webui.id
  cidr_ipv4         = aws_vpc.main_vpc.cidr_block
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ecs_webui" {
  security_group_id = aws_security_group.allow_ecs_webui.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_ecs_service" "ollama-service" {
  name            = "ollama"
  cluster         = aws_ecs_cluster.ollama-cluster.id
  task_definition = aws_ecs_task_definition.ollama_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.llm_tg.arn
    container_name   = "ollama-container"
    container_port   = 11434
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.allow_ecs_ollama.id]
    subnets          = [for subnet in aws_subnet.application_subnets : subnet.id]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_ecs_task_definition.ollama_task_definition]
}


resource "aws_security_group" "allow_ecs_ollama" {
  name        = "allow_ollama"
  description = "allow_ollama inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_ollama"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_ollama" {
  security_group_id = aws_security_group.allow_ecs_ollama.id
  cidr_ipv4         = aws_vpc.main_vpc.cidr_block
  from_port         = 11434
  ip_protocol       = "tcp"
  to_port           = 11434
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ecs_ollama" {
  security_group_id = aws_security_group.allow_ecs_ollama.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ecs_service" "grafana-service" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.ollama-cluster.id
  task_definition = aws_ecs_task_definition.grafana_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana_tg.arn
    container_name   = "grafana-container"
    container_port   = 3000
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.allow_ecs_grafana.id]
    subnets          = [for subnet in aws_subnet.application_subnets : subnet.id]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_ecs_task_definition.grafana_task_definition]
}


resource "aws_security_group" "allow_ecs_grafana" {
  name        = "allow_grafana"
  description = "allow_grafana inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_grafana"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_grafana" {
  security_group_id = aws_security_group.allow_ecs_grafana.id
  cidr_ipv4         = aws_vpc.main_vpc.cidr_block
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ecs_grafana" {
  security_group_id = aws_security_group.allow_ecs_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ecs_service" "prometheus-service" {
  name                               = "prometheus"
  cluster                            = aws_ecs_cluster.ollama-cluster.id
  task_definition                    = aws_ecs_task_definition.prometheus_task_definition.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
    container_name   = "prometheus-container"
    container_port   = 9090
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.allow_ecs_prometheus.id]
    subnets          = [for subnet in aws_subnet.application_subnets : subnet.id]
  }
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_ecs_task_definition.prometheus_task_definition]
}

resource "aws_security_group" "allow_ecs_prometheus" {
  name        = "allow_prometheus"
  description = "allow_prometheus inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_prometheus"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_prometheus" {
  security_group_id = aws_security_group.allow_ecs_prometheus.id
  cidr_ipv4         = aws_vpc.main_vpc.cidr_block
  from_port         = 9090
  ip_protocol       = "tcp"
  to_port           = 9090
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ecs_prom" {
  security_group_id = aws_security_group.allow_ecs_prometheus.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
