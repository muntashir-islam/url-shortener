

# Get current AWS account ID for correct DynamoDB ARN
data "aws_caller_identity" "current" {}

# DynamoDB table for storing short codes and URLs
resource "aws_dynamodb_table" "url_table" {
  name         = "UrlShortener"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }
}

# Zip the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/url_shortener.py"
  output_path = "${path.module}/lambda/url_shortener.zip"
}

# IAM Role for Lambda with inline policy for DynamoDB access
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-url-shortener"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

# Allow Lambda to write logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "url_shortener" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "url-shortener"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "url_shortener.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_table.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}

# HTTP API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "url-shortener-api"
  protocol_type = "HTTP"
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                = aws_apigatewayv2_api.api.id
  integration_type      = "AWS_PROXY"
  integration_uri       = aws_lambda_function.url_shortener.invoke_arn
  integration_method    = "POST"
  payload_format_version = "2.0"
}

# POST /shorten route
resource "aws_apigatewayv2_route" "post_shorten" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# GET /{short_code} route
resource "aws_apigatewayv2_route" "get_redirect" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /{short_code}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# API deployment stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Lambda permission to be invoked by API Gateway
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
