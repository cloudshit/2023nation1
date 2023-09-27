resource "aws_codepipeline" "codepipeline_product" {
  name     = "skills-pipeline-product"
  role_arn = aws_iam_role.codepipeline_role_product.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket_product.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.code_product.repository_name
        BranchName = "upstream"
        PollForSourceChanges = "false"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_product.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["source_output", "build_output"]
      version         = "1"

      configuration = {
        ApplicationName = aws_codedeploy_app.app_product.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg_product.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact = "source_output"
        Image1ArtifactName = "build_output"
        Image1ContainerName = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket_product" {
  bucket_prefix = "skills-artifacts-product"
  force_destroy = true
}


data "aws_iam_policy_document" "assume_role_pipeline_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role_product" {
  name               = "skills-role-codepipeline-product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline_product.json
}

data "aws_iam_policy_document" "codepipeline_policy_product" {
  statement {
    effect = "Allow"

    actions = [
      "kms:*",
      "codecommit:*",
      "codebuild:*",
      "logs:*",
      "codedeploy:*",
      "s3:*",
      "ecs:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy_product" {
  name   = "codepipeline_policy_product"
  role   = aws_iam_role.codepipeline_role_product.id
  policy = data.aws_iam_policy_document.codepipeline_policy_product.json
}

resource "aws_cloudwatch_event_rule" "event_product" {
  name = "skills-ci-event-product"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.code_product.arn}" ],
  "detail": {
     "event": [
       "referenceCreated",
       "referenceUpdated"
      ],
     "referenceType":["branch"],
     "referenceName": ["upstream"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "event_product" {
  target_id = "skills-ci-event-target-product"
  rule = aws_cloudwatch_event_rule.event_product.name
  arn = aws_codepipeline.codepipeline_product.arn
  role_arn = aws_iam_role.ci_product.arn
}

resource "aws_iam_role" "ci_product" {
  name = "skills-ci-product"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "ci_product" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ci_product" {
  name = "skills-ci-policy-product"
  policy = data.aws_iam_policy_document.ci_product.json
}

resource "aws_iam_role_policy_attachment" "ci_product" {
  policy_arn = aws_iam_policy.ci_product.arn
  role = aws_iam_role.ci_product.name
}
