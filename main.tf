provider "aws" {
  region = var.region
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_name}_exec_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda to manage Security Groups
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.lambda_name}_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeSecurityGroupRules",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "logs:*",
        "Resource": "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "tor_blocker" {
  filename         = "${path.module}/lambda_function.py.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  memory_size      = 128
  timeout          = 60

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.tor_block_sg.id]
  }

  environment {
    variables = {
      SECURITY_GROUP_ID = var.security_group_id
    }
  }

  source_code_hash = filebase64sha256("${path.module}/lambda_function.py.zip")
}

# Security Group for blocking TOR IPs
resource "aws_security_group" "tor_block_sg" {
  name        = "${var.lambda_name}_tor_block_sg"
  vpc_id      = var.vpc_id
  description = "Security group to block TOR exit nodes."
}

# CloudWatch Event Rule to trigger the Lambda function periodically
resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "${var.lambda_name}_schedule"
  description = "Periodic trigger for ${var.lambda_name}"
  schedule_expression = var.schedule_expression
}

# CloudWatch Event Target to associate the Lambda with the Event Rule
resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "${var.lambda_name}_target"
  arn       = aws_lambda_function.tor_blocker.arn
}

# Lambda Permission to allow CloudWatch to trigger it
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tor_blocker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
output "subnet_ids" {
  description = "List of subnet IDs used by the Lambda function"
  value       = var.subnet_ids
}
