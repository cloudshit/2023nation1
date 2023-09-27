data "aws_iam_policy_document" "assume_role_hook_stress" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "hook_stress" {
  name               = "skills-role-hook_stress"
  assume_role_policy = data.aws_iam_policy_document.assume_role_hook_stress.json
}

data "aws_iam_policy_document" "hook_stress" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "ecs:*",
      "codedeploy:PutLifecycleEventhook_stressExecutionStatus"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "hook_stress" {
  role   = aws_iam_role.hook_stress.name
  policy = data.aws_iam_policy_document.hook_stress.json
}

data "archive_file" "hook_stress" {
  type        = "zip"
  source_file = "../src/hook_stress.js"
  output_path = "../temp/hook_stress.zip"
}

resource "aws_lambda_function" "hook_stress" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "../temp/hook_stress.zip"
  function_name = "skills-hook_stress"
  role          = aws_iam_role.hook_stress.arn
  handler       = "hook_stress.handler"

  source_code_hash = data.archive_file.hook_stress.output_base64sha256

  runtime = "nodejs16.x"
}
