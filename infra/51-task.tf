data "aws_iam_policy_document" "assume_role_execution_stress" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "execution_stress" {
  name               = "skills-role-execution-stress"
  assume_role_policy = data.aws_iam_policy_document.assume_role_execution_stress.json
}

data "aws_iam_policy_document" "execution_stress" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "ecr:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execution_stress" {
  role   = aws_iam_role.execution_stress.name
  policy = data.aws_iam_policy_document.execution_stress.json
}

resource "aws_ecs_task_definition" "td_stress" {
  family                   = "skills-td-stress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn = aws_iam_role.execution_stress.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${aws_ecr_repository.skills_ecr_stress.repository_url}:latest",
    "cpu": 512,
    "memory": 1024,
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "healthCheck": {
      "command": [
        "CMD-SHELL",
        "curl -fLs http://localhost:8080/healthcheck > /dev/null || exit 1"
      ],
      "interval": 5,
      "timeout": 2,
      "retries": 1,
      "startPeriod": 0
    },
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "wsi-log-cluster",
        "awslogs-region": "ap-northeast-2",
        "awslogs-create-group": "true",
        "awslogs-stream-prefix": "stress"
      }
    }
  }
]
DEFINITION
}

resource "aws_security_group" "ecs_stress" {
  name = "skills-ecs-sg-stress"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_ecs_service" "svc_stress" {
  name            = "skills-svc-stress"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.td_stress.arn
  desired_count   = 2
  health_check_grace_period_seconds = 0
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.private_c.id
    ]

    security_groups = [
      aws_security_group.ecs_stress.id
    ]

    assign_public_ip = false
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg1_stress.arn
    container_name   = "app"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, capacity_provider_strategy]
  }
}
