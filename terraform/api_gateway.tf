# API Gateway REST API
resource "aws_api_gateway_rest_api" "city_facts_api" {
  count       = var.enable_frontend ? 1 : 0
  name        = "${local.full_project_name}-api"
  description = "API Gateway for City Facts Lambda functions"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource for /direct endpoint
resource "aws_api_gateway_resource" "direct" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  parent_id   = aws_api_gateway_rest_api.city_facts_api[0].root_resource_id
  path_part   = "direct"
}

# API Gateway Resource for /agent endpoint
resource "aws_api_gateway_resource" "agent" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  parent_id   = aws_api_gateway_rest_api.city_facts_api[0].root_resource_id
  path_part   = "agent"
}

# POST method for /direct
resource "aws_api_gateway_method" "direct_post" {
  count         = var.enable_frontend ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id   = aws_api_gateway_resource.direct[0].id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[0].id
}

# POST method for /agent
resource "aws_api_gateway_method" "agent_post" {
  count         = var.enable_frontend ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id   = aws_api_gateway_resource.agent[0].id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[0].id
}

# Lambda integration for /direct
resource "aws_api_gateway_integration" "direct_lambda" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.direct[0].id
  http_method = aws_api_gateway_method.direct_post[0].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.city_facts_direct.invoke_arn
}

# Lambda integration for /agent
resource "aws_api_gateway_integration" "agent_lambda" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.agent[0].id
  http_method = aws_api_gateway_method.agent_post[0].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.city_facts_agent.invoke_arn
}

# Lambda permissions for API Gateway to invoke functions
resource "aws_lambda_permission" "apigw_direct" {
  count         = var.enable_frontend ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.city_facts_direct.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.city_facts_api[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_agent" {
  count         = var.enable_frontend ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.city_facts_agent.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.city_facts_api[0].execution_arn}/*/*"
}

# CORS configuration for /direct OPTIONS
resource "aws_api_gateway_method" "direct_options" {
  count         = var.enable_frontend ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id   = aws_api_gateway_resource.direct[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "direct_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.direct[0].id
  http_method = aws_api_gateway_method.direct_options[0].http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "direct_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.direct[0].id
  http_method = aws_api_gateway_method.direct_options[0].http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "direct_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.direct[0].id
  http_method = aws_api_gateway_method.direct_options[0].http_method
  status_code = aws_api_gateway_method_response.direct_options[0].status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# CORS configuration for /agent OPTIONS
resource "aws_api_gateway_method" "agent_options" {
  count         = var.enable_frontend ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id   = aws_api_gateway_resource.agent[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "agent_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.agent[0].id
  http_method = aws_api_gateway_method.agent_options[0].http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "agent_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.agent[0].id
  http_method = aws_api_gateway_method.agent_options[0].http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "agent_options" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  resource_id = aws_api_gateway_resource.agent[0].id
  http_method = aws_api_gateway_method.agent_options[0].http_method
  status_code = aws_api_gateway_method_response.agent_options[0].status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "city_facts_api" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.direct[0].id,
      aws_api_gateway_resource.agent[0].id,
      aws_api_gateway_method.direct_post[0].id,
      aws_api_gateway_method.agent_post[0].id,
      aws_api_gateway_integration.direct_lambda[0].id,
      aws_api_gateway_integration.agent_lambda[0].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.direct_lambda,
    aws_api_gateway_integration.agent_lambda,
    aws_api_gateway_integration.direct_options,
    aws_api_gateway_integration.agent_options,
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  count         = var.enable_frontend ? 1 : 0
  deployment_id = aws_api_gateway_deployment.city_facts_api[0].id
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  stage_name    = "prod"
}

# Method settings for rate limiting (applies to all methods in stage)
resource "aws_api_gateway_method_settings" "all" {
  count       = var.enable_frontend ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.city_facts_api[0].id
  stage_name  = aws_api_gateway_stage.prod[0].stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 25
  }
}
