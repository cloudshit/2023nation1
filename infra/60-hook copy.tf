data "aws_iam_policy_document" "assume_role_hook_product" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "hook_product" {
  name               = "skills-role-hook_product"
  assume_role_policy = data.aws_iam_policy_document.assume_role_hook_product.json
}

data "aws_iam_policy_document" "hook_product" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "ecs:*",
      "codedeploy:PutLifecycleEventhook_productExecutionStatus"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "hook_product" {
  role   = aws_iam_role.hook_product.name
  policy = data.aws_iam_policy_document.hook_product.json
}

data "archive_file" "hook_product" {
  type        = "zip"
  source_file = "../src/hook_product.js"
  output_path = "../temp/hook_product.zip"
}

resource "aws_lambda_function" "hook_product" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "../temp/hook_product.zip"
  function_name = "skills-hook_product"
  role          = aws_iam_role.hook_product.arn
  handler       = "hook_product.handler"

  source_code_hash = data.archive_file.hook_product.output_base64sha256

  runtime = "nodejs16.x"
}
