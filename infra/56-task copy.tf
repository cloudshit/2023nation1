data "aws_iam_policy_document" "assume_role_execution_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "execution_product" {
  name               = "skills-role-execution-product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_execution_product.json
}

data "aws_iam_policy_document" "execution_product" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "ecr:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execution_product" {
  role   = aws_iam_role.execution_product.name
  policy = data.aws_iam_policy_document.execution_product.json
}

data "aws_iam_policy_document" "assume_role_task_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_product" {
  name               = "skills-role-task-product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_task_product.json
}

data "aws_iam_policy_document" "task_product" {
  statement {
    effect = "Allow"

    actions = [
      "secretmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.db.arn
    ]
  }
}

resource "aws_iam_role_policy" "task_product" {
  role   = aws_iam_role.task_product.name
  policy = data.aws_iam_policy_document.task_product.json
}

resource "aws_ecs_task_definition" "td_product" {
  family                   = "skills-td-product"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn = aws_iam_role.execution_product.arn
  task_role_arn = aws_iam_role.task_product.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${aws_ecr_repository.skills_ecr_product.repository_url}:latest",
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
    "essential": true
  }
]
DEFINITION
}

resource "aws_security_group" "ecs_product" {
  name = "skills-ecs-sg-product"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_ecs_service" "svc_product" {
  name            = "skills-svc-product"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.td_product.arn
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
      aws_security_group.ecs_product.id
    ]

    assign_public_ip = false
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg1_product.arn
    container_name   = "app"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, capacity_provider_strategy]
  }
}
