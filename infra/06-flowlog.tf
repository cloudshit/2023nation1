resource "aws_flow_log" "flowlog" {
  iam_role_arn    = aws_iam_role.flowlog.arn
  log_destination = aws_cloudwatch_log_group.flowlog.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "flowlog" {
  name = "flowlog"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlog" {
  name               = "flowlog"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "flowlog" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlog" {
  name   = "flowlog"
  role   = aws_iam_role.flowlog.id
  policy = data.aws_iam_policy_document.flowlog.json
}
