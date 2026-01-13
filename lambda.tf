# Lambda function for direct city facts (direct model access)
resource "aws_lambda_function" "city_facts_direct" {
  filename         = "city_facts_direct.zip"
  function_name    = "${var.project_name}-city-facts-direct"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 128
  publish         = false

  # Ignore changes to code since it's managed externally
  lifecycle {
    ignore_changes = [
      source_code_hash
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_logs_direct,
  ]
}

# Lambda function for city facts via Bedrock agent
resource "aws_lambda_function" "city_facts_agent" {
  filename         = "city_facts_agent.zip"
  function_name    = "${var.project_name}-city-facts-agent"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 128
  publish         = false

  # Ignore changes to code since it's managed externally
  lifecycle {
    ignore_changes = [
      source_code_hash
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_logs_agent,
  ]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Bedrock permissions for Lambda
resource "aws_iam_role_policy" "bedrock_policy" {
  name = "${var.project_name}-bedrock-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:InvokeAgent"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch log groups
resource "aws_cloudwatch_log_group" "lambda_logs_direct" {
  name              = "/aws/lambda/${var.project_name}-city-facts-direct"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_logs_agent" {
  name              = "/aws/lambda/${var.project_name}-city-facts-agent"
  retention_in_days = 14
}