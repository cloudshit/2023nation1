data "aws_iam_policy_document" "assume_role_build_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "build_product" {
  name               = "skills-role-build-product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_build_product.json
}

data "aws_iam_policy_document" "build_product" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "ecr:*",
      "codestar-connections:*",
      "codecommit:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "build_product" {
  role   = aws_iam_role.build_product.name
  policy = data.aws_iam_policy_document.build_product.json
}

resource "aws_codebuild_project" "build_product" {
  name          = "skills-build-product"
  service_role  = aws_iam_role.build_product.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/skills-build-product"
      stream_name = "build_log"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
