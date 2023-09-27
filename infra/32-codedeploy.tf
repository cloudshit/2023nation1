data "aws_iam_policy_document" "assume_role_deploy_stress" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "deploy_stress" {
  name               = "skills-role-deploy-stress"
  assume_role_policy = data.aws_iam_policy_document.assume_role_deploy_stress.json
}

data "aws_iam_policy_document" "deploy_stress" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "ecr:*",
      "ecs:*",
      "elasticloadbalancing:*",
      "ec2:*",
      "lambda:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy_stress" {
  role   = aws_iam_role.deploy_stress.name
  policy = data.aws_iam_policy_document.deploy_stress.json
}

resource "aws_codedeploy_app" "app_stress" {
  compute_platform = "ECS"
  name             = "skills-app-stress"
}

resource "aws_codedeploy_deployment_group" "dg_stress" {
  app_name               = aws_codedeploy_app.app_stress.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "skills-dg-stress"
  service_role_arn       = aws_iam_role.deploy_stress.arn

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
    service_name = aws_ecs_service.svc_stress.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener.arn]
      }

      target_group {
        name = aws_lb_target_group.tg1_stress.name
      }

      target_group {
        name = aws_lb_target_group.tg2_stress.name
      }
    }
  }
}
