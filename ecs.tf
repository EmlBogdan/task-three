resource "aws_ecs_cluster" "ollama-cluster" {
  name = "ollama-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "ecs_secretmanager-read"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.db_url.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-staging-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_secretsmanager_secret" "db_url" {
  name                    = "databaseurl"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_url_value" {
  secret_id     = aws_secretsmanager_secret.db_url.id
  secret_string = "postgresql://${aws_db_instance.postgres.username}:${urlencode(aws_db_instance.postgres.password)}@${aws_db_instance.postgres.endpoint}/openwebui"
}
