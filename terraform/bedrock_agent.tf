# Bedrock Agent for City Facts
resource "aws_bedrockagent_agent" "city_facts_agent" {
  agent_name                    = "${local.full_project_name}-city-facts-agent"
  agent_resource_role_arn       = aws_iam_role.bedrock_agent_role.arn
  foundation_model              = "anthropic.claude-3-haiku-20240307-v1:0"
  description                   = "Agent that provides interesting facts about cities around the world"
  idle_session_ttl_in_seconds   = 1800
  prepare_agent                 = true
  skip_resource_in_use_check    = false
  
  instruction = <<EOF
You are a knowledgeable city facts assistant. Your role is to provide interesting, accurate, and engaging facts about cities around the world.

When a user asks about a city, you should:
1. Use the knowledge base to find relevant data about air quality, water pollution, and cost of living
2. Use the city facts action group to get general interesting facts about the city
3. Combine information from both sources to provide comprehensive answers
4. Present the information in an engaging and educational manner

Focus on unique aspects that make each city special, including:
- Historical significance and founding
- Cultural landmarks and traditions
- Geographical features
- Economic importance and cost of living
- Environmental factors like air quality
- Architectural highlights
- Population and demographics
- Interesting trivia and lesser-known facts

Always be helpful, informative, and enthusiastic about sharing knowledge about cities. When you have data from the knowledge base, reference it appropriately and combine it with general city facts for a complete picture.
EOF

  tags = {
    Environment = "development"
    Project     = local.full_project_name
  }
}

# IAM role for Bedrock Agent
resource "aws_iam_role" "bedrock_agent_role" {
  name = "${local.full_project_name}-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Bedrock Agent to invoke foundation models and access knowledge base
resource "aws_iam_role_policy" "bedrock_agent_model_policy" {
  name = "${local.full_project_name}-bedrock-agent-model-policy"
  role = aws_iam_role.bedrock_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.deploy_knowledge_base ? [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve"
        ]
        Resource = [
          aws_bedrockagent_knowledge_base.city_facts_simple[0].arn
        ]
      }
    ] : [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      }
    ]
  })
}

# Action Group for the agent (will invoke our Lambda function)
resource "aws_bedrockagent_agent_action_group" "city_facts_action_group" {
  agent_id                     = aws_bedrockagent_agent.city_facts_agent.agent_id
  agent_version                = "DRAFT"
  action_group_name            = "CityFactsActionGroup"
  description                  = "Action group that provides city facts by invoking Lambda function"
  prepare_agent                = true
  skip_resource_in_use_check   = true
  
  action_group_executor {
    lambda = aws_lambda_function.city_facts_direct.arn
  }
  
  api_schema {
    payload = jsonencode({
      openapi = "3.0.0"
      info = {
        title   = "City Facts API"
        version = "1.0.0"
        description = "API for getting interesting facts about cities"
      }
      paths = {
        "/city-facts" = {
          post = {
            summary = "Get facts about a city"
            description = "Returns 10 interesting facts about the specified city"
            operationId = "getCityFacts"
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                    properties = {
                      city = {
                        type = "string"
                        description = "The name of the city to get facts about"
                      }
                    }
                    required = ["city"]
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "Successful response with city facts"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        city = {
                          type = "string"
                          description = "The city name"
                        }
                        facts = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                          description = "List of interesting facts about the city"
                        }
                        total_facts = {
                          type = "integer"
                          description = "Number of facts returned"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    })
  }
}

# Lambda permission for Bedrock Agent to invoke the function
resource "aws_lambda_permission" "allow_bedrock_agent" {
  statement_id  = "AllowBedrockAgentInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.city_facts_direct.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.city_facts_agent.agent_arn
}