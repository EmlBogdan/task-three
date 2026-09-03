resource "aws_ecs_task_definition" "webui_task_definition" {
  family                   = "webui"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name      = "webui-container"
    image     = "hashicorp/http-echo"
    command   = ["-listen=:8080", "-text=hello-world"]
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
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
    image     = "hashicorp/http-echo"
    command   = ["-listen=:11434", "-text=hello-world"]
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
      {
        containerPort = 11434
        hostPort      = 11434
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "ollama"
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
    image     = "hashicorp/http-echo"
    command   = ["-listen=:3000", "-text=hello-world"]
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "grafana"
  }
}

resource "aws_ecs_task_definition" "prometheus_task_definition" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "prometheus-data"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.promeheus-efs.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus-data.id
        iam             = "ENABLED"
      }
    }
  }
  container_definitions = jsonencode([{
    name      = "prometheus-container"
    image     = "hashicorp/http-echo"
    command   = ["-listen=:9090", "-text=hello-world"]
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
      {
        containerPort = 9090
        hostPort      = 9090
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "prometheus-data"
        containerPath = "/prometheus"
        readOnly      = false
      }
    ]
  }])
  tags = {
    Environment = "staging"
    Application = "prometheus"
  }
}

