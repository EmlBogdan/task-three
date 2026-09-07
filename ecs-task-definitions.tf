resource "aws_ecs_task_definition" "webui_task_definition" {
  family                   = "webui"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name  = "webui-container"
      image = "${data.aws_ecr_repository.ollama-repository.repository_url}:webui-base-image"
      environment = [
        {
          name  = "OLLAMA_BASE_URL"
          value = "https://ollama.universal-domain.online"
        },
        {
          name  = "DB_HOST"
          value = "${aws_db_instance.postgres.address}"
        },
        {
          name  = "DB_NAME"
          value = "${aws_db_instance.postgres.db_name}"
        }
      ]
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${aws_db_instance.postgres.master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "DB_PASS"
          valueFrom = "${aws_db_instance.postgres.master_user_secret[0].secret_arn}:password::"
        }
      ]
      entryPoint = ["sh", "-c"]
      command    = ["export DATABASE_URL=\"postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME\" && bash start.sh"]
      cpu        = 1024
      memory     = 2048
      essential  = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    },
  ])
  tags = {
    Environment = "staging"
    Application = "webui"
  }
  depends_on = [aws_db_instance.postgres]
}

resource "aws_ecs_task_definition" "ollama_task_definition" {
  family                   = "ollama"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 2048
  memory                   = 4096
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name      = "ollama-container"
      image     = "${data.aws_ecr_repository.ollama-repository.repository_url}:ollama-base-image"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 11434
          hostPort      = 11434
        }
      ]
    },
    {
      name      = "grafana-agent-container"
      image     = "${data.aws_ecr_repository.ollama-repository.repository_url}:grafana-agent"
      cpu       = 1024
      memory    = 2048
      essential = true
    }
  ])
  tags = {
    Environment = "staging"
    Application = "ollama"
  }
}


resource "aws_ecs_task_definition" "grafana_task_definition" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 2048
  memory                   = 4096
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.monitoring_host_role.arn
  container_definitions = jsonencode([{
    name      = "grafana-container"
    image     = "${data.aws_ecr_repository.ollama-repository.repository_url}:grafana-base-image"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
      }
    ]
    }, {
    name      = "alertmanager-container"
    image     = "${data.aws_ecr_repository.ollama-repository.repository_url}:alertmanager"
    cpu       = 1024
    memory    = 2048
    essential = true
    portMappings = [
      {
        containerPort = 9093
        hostPort      = 9093
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
    image     = "${data.aws_ecr_repository.ollama-repository.repository_url}:prometheus-base-image"
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

