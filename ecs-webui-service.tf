resource "aws_ecs_task_definition" "webui_task_definition" {
  family                   = "webui"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name      = "webui-container"
    image     = "alpine"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMapping = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "webui"
  }
}

resource "aws_ecs_task_definition" "ollama_task_definition" {
  family                   = "ollama"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name      = "ollama-container"
    image     = "alpine"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMapping = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "webui"
  }
}


resource "aws_ecs_task_definition" "grafana_task_definition" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name      = "grafana-container"
    image     = "alpine"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMapping = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "webui"
  }
}

resource "aws_ecs_task_definition" "prometheus_task_definition" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name      = "prometheus-container"
    image     = "alpine"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMapping = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "webui"
  }
}

# resource "aws_ecs_service" "webui-service" {
#   name            = "webui-service"
#   cluster         = aws_ecs_cluster.ollama-cluster.id
#   task_definition = aws_ecs_task_definition.webui_task_definition.arn
#   desired_count   = 1

#   launch_type      = "FARGATE"
#   platform_version = "LATEST"
#   network_configuration {
#     security_groups = [aws_security_group.ollama_alb_sg.id]
#     subnets         = [for subnet in aws_subnet.application_subnets : subnet.id]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.webui_tg.arn
#     container_name   = "webui"
#     container_port   = 8080
#   }

#   depends_on = [aws_lb_listener.webui_listener, aws_iam_role_policy_attachment.ecs_task_execution_role]

#   tags = {
#     Environment = "staging"
#     Application = "webui"
#   }
# }

