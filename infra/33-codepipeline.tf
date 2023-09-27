resource "aws_codepipeline" "codepipeline_stress" {
  name     = "skills-pipeline-stress"
  role_arn = aws_iam_role.codepipeline_role_stress.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket_stress.bucket
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
        RepositoryName = aws_codecommit_repository.code_stress.repository_name
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
        ProjectName = aws_codebuild_project.build_stress.name
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
        ApplicationName = aws_codedeploy_app.app_stress.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg_stress.deployment_group_name
        TaskDefinitionTemplateArtifact = "source_output"
        AppSpecTemplateArtifact = "source_output"
        Image1ArtifactName = "build_output"
        Image1ContainerName = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket_stress" {
  bucket_prefix = "skills-artifacts-stress"
  force_destroy = true
}


data "aws_iam_policy_document" "assume_role_pipeline_stress" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role_stress" {
  name               = "skills-role-codepipeline-stress"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline_stress.json
}

data "aws_iam_policy_document" "codepipeline_policy_stress" {
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

resource "aws_iam_role_policy" "codepipeline_policy_stress" {
  name   = "codepipeline_policy_stress"
  role   = aws_iam_role.codepipeline_role_stress.id
  policy = data.aws_iam_policy_document.codepipeline_policy_stress.json
}

resource "aws_cloudwatch_event_rule" "event_stress" {
  name = "skills-ci-event-stress"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.code_stress.arn}" ],
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

resource "aws_cloudwatch_event_target" "event_stress" {
  target_id = "skills-ci-event-target-stress"
  rule = aws_cloudwatch_event_rule.event_stress.name
  arn = aws_codepipeline.codepipeline_stress.arn
  role_arn = aws_iam_role.ci_stress.arn
}

resource "aws_iam_role" "ci_stress" {
  name = "skills-ci-stress"
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

data "aws_iam_policy_document" "ci_stress" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ci_stress" {
  name = "skills-ci-policy-stress"
  policy = data.aws_iam_policy_document.ci_stress.json
}

resource "aws_iam_role_policy_attachment" "ci_stress" {
  policy_arn = aws_iam_policy.ci_stress.arn
  role = aws_iam_role.ci_stress.name
}
