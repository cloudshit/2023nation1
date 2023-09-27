data "aws_iam_policy_document" "assume_role_deploy_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "deploy_product" {
  name               = "skills-role-deploy-product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_deploy_product.json
}

data "aws_iam_policy_document" "deploy_product" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "ecr:*",
      "ecs:*",
      "elasticloadbalancing:*",
      "ec2:*",
      "lambda:*",
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy_product" {
  role   = aws_iam_role.deploy_product.name
  policy = data.aws_iam_policy_document.deploy_product.json
}

resource "aws_codedeploy_app" "app_product" {
  compute_platform = "ECS"
  name             = "skills-app-product"
}

resource "aws_codedeploy_deployment_group" "dg_product" {
  app_name               = aws_codedeploy_app.app_product.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "skills-dg-product"
  service_role_arn       = aws_iam_role.deploy_product.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.svc_product.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener.arn]
      }

      target_group {
        name = aws_lb_target_group.tg1_product.name
      }

      target_group {
        name = aws_lb_target_group.tg2_product.name
      }
    }
  }
}
