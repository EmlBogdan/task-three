resource "aws_efs_file_system" "promeheus-efs" {
  creation_token = "ecs-shared-storage"

  encrypted  = true
  kms_key_id = aws_kms_key.efs.arn

  performance_mode = "generalPurpose"

  throughput_mode = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "ecs-shared-storage"
    Environment = "production"
  }
}

resource "aws_kms_key" "efs" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_efs_mount_target" "main" {
  count           = length(var.Private_CIDRs)
  file_system_id  = aws_efs_file_system.promeheus-efs.id
  subnet_id       = aws_subnet.application_subnets[count.index].id
  security_groups = [aws_security_group.prometheus_efs_sg.id]
}

resource "aws_security_group" "prometheus_efs_sg" {
  name        = "prometheus_efs_sg"
  description = "Security group for efs"
  vpc_id      = aws_vpc.main_vpc.id
  tags = {
    Name = "prometheus_efs_sg"
  }
}

resource "aws_efs_access_point" "prometheus-data" {
  file_system_id = aws_efs_file_system.promeheus-efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/prometheus"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name    = "prometheus-access-point"
    Purpose = "prometheus-data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_efs_access" {
  security_group_id = aws_security_group.prometheus_efs_sg.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

resource "aws_vpc_security_group_egress_rule" "allow_all_efs_outcoming_traffic_ipv4" {
  security_group_id = aws_security_group.prometheus_efs_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_iam_role" "ecs_task" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "ecs-task-efs-access"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.promeheus-efs.arn
      }
    ]
  })
}

resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.promeheus-efs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceEncryptionInTransit"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "*"
        Resource = aws_efs_file_system.promeheus-efs.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowECSTaskAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task.arn
        }
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.promeheus-efs.arn
      }
    ]
  })
}


