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
          name  = "DATABASE_URL"
          value = "postgresql://${aws_db_instance.postgres.username}:${urlencode(aws_db_instance.postgres.password)}@${aws_db_instance.postgres.endpoint}/openwebui"
        },
        {
          name  = "OLLAMA_BASE_URL"
          value = "http://${aws_lb.ollama_alb.dns_name}:11434"
        }
      ]
      cpu       = 1024
      memory    = 2048
      essential = true
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
      image     = "grafana/agent:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      environment = [
        {
          name = "AGENT_CONFIG"
          value = base64encode(<<-EOF
        server: 
          log_level: info
        metrics: 
          global: 
            scrape_interval: 15s 
            remote_write: 
              - url: https://prometheus.universal-domain.online/api/v1/write
          configs: 
            - name: llm-agent 
              scrape_configs: 
                - job_name: node
                  static_configs:
                    - targets: ["127.0.0.1:11434"]

        integrations:
          node_exporter:
            enabled: true
            include_exporter_metrics: true
        EOF
          )
        }
      ]
      entryPoint = ["/bin/sh", "-c"]
      command = [
        "echo $AGENT_CONFIG | base64 -d > /tmp/agent.yaml && /bin/grafana-agent -config.file=/tmp/agent.yaml"
      ]
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
    environment = [
      {
        name = "DATASOURCES_CONFIG"
        value = base64encode(<<-EOF
        apiVersion: 1

        datasources:
          - name: CloudWatch
            type: cloudwatch
            uid: cloudwatch-ds
            isDefault: false
            jsonData:
              authType: default
              defaultRegion: us-east-1

          - name: Prometheus
            type: prometheus
            uid: prometheus-ds
            access: proxy
            url: https://prometheus.universal-domain.online/
            jsonData:
              httpMethod: POST
              timeInterval: 15s
          
          - name: Alertmanager
            type: alertmanager
            uid: alertmanager-ds
            access: proxy
            url: http://localhost:9093
            jsonData:
              implementation: prometheus
              handleGrafanaManagedAlerts: true
            isDefault: false
            editable: false
        EOF
        )
      },
      {
        name  = "GF_PATHS_PROVISIONING"
        value = "/tmp/provisioning"
      }
    ]
    entryPoint = ["/bin/sh", "-c"]
    command = [
      "mkdir -p /tmp/provisioning/datasources && cp -r /etc/grafana/provisioning/* /tmp/provisioning/ && echo $DATASOURCES_CONFIG | base64 -d > /tmp/provisioning/datasources/datasources.yaml && /run.sh"
    ]
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
      }
    ]
    }, {
    name      = "alertmanager-container"
    image     = "prom/alertmanager"
    cpu       = 1024
    memory    = 2048
    essential = true
    environment = [
      {
        name = "ALERTMANAGER_CONFIG"
        value = base64encode(<<-EOF
        global:
          smtp_smarthost: 'smtp.gmail.com:587'
          smtp_from: 'alertfromalertman@gmail.com'
          smtp_auth_username: 'alertfromalertman@gmail.com'
          smtp_auth_password: 'efsxtyfpdsjtjbij'
          smtp_require_tls: true

        route:
          group_by: ['alertname', 'instance']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 4h
          receiver: 'bieme'

        receivers:
          - name: 'bieme'
            email_configs:
              - to: 'bieme@softserveinc.com'
                send_resolved: true
        EOF
        )
      }
    ]
    entryPoint = ["/bin/sh", "-c"]
    command = [
      "echo $ALERTMANAGER_CONFIG | base64 -d > /tmp/alertmanager.yml && /bin/alertmanager --config.file=/tmp/alertmanager.yml"
    ]
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
    environment = [
      {
        name = "PROMETHEUS_CONFIG"
        value = base64encode(<<-EOF
        global:
          scrape_interval: 15s
          evaluation_interval: 15s
          
        scrape_configs:
          - job_name: "prometheus"
            static_configs:
              - targets: ["localhost:9090"]
        EOF
        )
      }
    ]
    entryPoint = ["/bin/sh", "-c"]
    command = [
      "echo $PROMETHEUS_CONFIG | base64 -d > /tmp/prometheus.yml && /bin/prometheus --config.file=/tmp/prometheus.yml --storage.tsdb.path=/prometheus --web.enable-remote-write-receiver"
    ]
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

