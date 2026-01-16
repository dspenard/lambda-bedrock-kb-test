# Cognito User Pool
resource "aws_cognito_user_pool" "city_facts_pool" {
  count = var.enable_frontend ? 1 : 0
  name  = "${local.full_project_name}-user-pool"

  # Allow users to sign in with email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }

  # Allow deletion for test/dev environments
  deletion_protection = "INACTIVE"

  tags = {
    Name = "${local.full_project_name}-user-pool"
  }
}

# Cognito User Pool Client (for React app)
resource "aws_cognito_user_pool_client" "city_facts_client" {
  count        = var.enable_frontend ? 1 : 0
  name         = "${local.full_project_name}-client"
  user_pool_id = aws_cognito_user_pool.city_facts_pool[0].id

  # OAuth settings
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:3000", "http://localhost:3000/"]
  logout_urls                          = ["http://localhost:3000", "http://localhost:3000/"]
  supported_identity_providers         = ["COGNITO"]

  # Token validity
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour
  refresh_token_validity = 30 # 30 days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Enable SRP authentication
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Prevent accidental deletion
  prevent_user_existence_errors = "ENABLED"

  read_attributes = [
    "email",
    "email_verified"
  ]

  write_attributes = [
    "email"
  ]
}

# Cognito User Pool Domain (for hosted UI - optional)
resource "aws_cognito_user_pool_domain" "city_facts_domain" {
  count        = var.enable_frontend ? 1 : 0
  domain       = "${local.full_project_name}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.city_facts_pool[0].id
}

# API Gateway Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  count         = var.enable_frontend ? 1 : 0
  name          = "${local.full_project_name}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.city_facts_api[0].id
  provider_arns = [aws_cognito_user_pool.city_facts_pool[0].arn]
}
