# Working Knowledge Base configuration using OpenSearch Serverless
# This uses the manually created OpenSearch collection and vector index

# Data source to reference the existing S3 bucket
# Only used when knowledge_base_bucket_name is provided
data "aws_s3_bucket" "knowledge_base" {
  count  = var.knowledge_base_bucket_name != "" ? 1 : 0
  bucket = var.knowledge_base_bucket_name
}

# OpenSearch Serverless Collection for Knowledge Base
resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = "${substr(var.project_name, 0, 20)}-kb-coll"
  type = "VECTORSEARCH"

  tags = {
    Environment = "development"
    Project     = var.project_name
  }

  depends_on = [
    aws_opensearchserverless_security_policy.knowledge_base_encryption,
    aws_opensearchserverless_security_policy.knowledge_base_network,
    aws_opensearchserverless_access_policy.knowledge_base
  ]
}

# OpenSearch Serverless Access Policy
resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name = "${substr(var.project_name, 0, 20)}-kb-access"
  type = "data"
  
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${substr(var.project_name, 0, 20)}-kb-coll"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource = [
            "index/${substr(var.project_name, 0, 20)}-kb-coll/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
        }
      ]
      Principal = [
        aws_iam_role.knowledge_base_role.arn
      ]
    }
  ])
}

# OpenSearch Serverless Network Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  name = "${substr(var.project_name, 0, 20)}-kb-network"
  type = "network"
  
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${substr(var.project_name, 0, 20)}-kb-coll"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${substr(var.project_name, 0, 20)}-kb-coll"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch Serverless Encryption Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  name = "${substr(var.project_name, 0, 18)}-kb-encrypt"
  type = "encryption"
  
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${substr(var.project_name, 0, 20)}-kb-coll"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

# IAM Role for Knowledge Base
resource "aws_iam_role" "knowledge_base_role" {
  name = "${var.project_name}-knowledge-base-role"

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

# IAM Policy for Knowledge Base to access S3
resource "aws_iam_role_policy" "knowledge_base_s3_policy" {
  name = "${var.project_name}-knowledge-base-s3-policy"
  role = aws_iam_role.knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.knowledge_base[0].arn,
          "${data.aws_s3_bucket.knowledge_base[0].arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Knowledge Base to access OpenSearch
resource "aws_iam_role_policy" "knowledge_base_opensearch_policy" {
  name = "${var.project_name}-knowledge-base-opensearch-policy"
  role = aws_iam_role.knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = [
          aws_opensearchserverless_collection.knowledge_base.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ]
        Resource = [
          "${aws_opensearchserverless_collection.knowledge_base.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Knowledge Base to access Bedrock models
resource "aws_iam_role_policy" "knowledge_base_bedrock_policy" {
  name = "${var.project_name}-knowledge-base-bedrock-policy"
  role = aws_iam_role.knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-text-v1"
        ]
      }
    ]
  })
}

# Random ID for S3 bucket naming (not used but kept for compatibility)
resource "random_id" "kb_suffix" {
  byte_length = 6
}

# Bedrock Knowledge Base using OpenSearch Serverless
resource "aws_bedrockagent_knowledge_base" "city_facts_simple" {
  count    = var.knowledge_base_bucket_name != "" ? 1 : 0
  name     = "${var.project_name}-city-facts-kb-s3"
  role_arn = aws_iam_role.knowledge_base_role.arn
  
  description = "Knowledge base containing city facts, air quality, and cost of living data (S3 Vectors)"

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "embeddings"
        text_field     = "text"
        metadata_field = "bedrock-metadata"
      }
    }
  }
  
  tags = {
    Environment = "development"
    Project     = var.project_name
  }
}

# Data Source 1: Air Quality and Water Pollution CSV
resource "aws_bedrockagent_data_source" "air_quality_data_simple" {
  count             = var.knowledge_base_bucket_name != "" ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.city_facts_simple[0].id
  name              = "city-air-quality-water-pollution"
  description       = "World cities air quality and water pollution data from 2021"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = data.aws_s3_bucket.knowledge_base[0].arn
      inclusion_prefixes = [
        "world_cities_air_quality_water_pollution_2021.csv"
      ]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }

  data_deletion_policy = "RETAIN"
}

# Data Source 2: Cost of Living CSV
resource "aws_bedrockagent_data_source" "cost_of_living_data_simple" {
  count             = var.knowledge_base_bucket_name != "" ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.city_facts_simple[0].id
  name              = "city-cost-of-living"
  description       = "World cities cost of living data from 2018"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = data.aws_s3_bucket.knowledge_base[0].arn
      inclusion_prefixes = [
        "world_cities_cost_of_living_2018.csv"
      ]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }

  data_deletion_policy = "RETAIN"
}

# Associate Knowledge Base with Agent
resource "aws_bedrockagent_agent_knowledge_base_association" "city_facts_kb_association_simple" {
  count                = var.knowledge_base_bucket_name != "" ? 1 : 0
  agent_id             = aws_bedrockagent_agent.city_facts_agent.agent_id
  agent_version        = "DRAFT"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.city_facts_simple[0].id
  description          = "Association between city facts agent and knowledge base"
  knowledge_base_state = "ENABLED"
}