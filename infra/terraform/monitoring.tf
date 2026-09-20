data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/hcn-flow-logs"
  retention_in_days = 7

  tags = {
    Name    = "hcn-vpc-flow-logs"
    Project = "hybrid-cloud-network-lab"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "hcn-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = {
    Project = "hybrid-cloud-network-lab"
  }
}

data "aws_iam_policy_document" "flow_logs_delivery" {
  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name   = "hcn-vpc-flow-logs-delivery"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_delivery.json
}

resource "aws_flow_log" "hcn" {
  vpc_id                   = aws_vpc.hcn.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  max_aggregation_interval = 60

  tags = {
    Name    = "hcn-vpc-flow-log"
    Project = "hybrid-cloud-network-lab"
  }
}
