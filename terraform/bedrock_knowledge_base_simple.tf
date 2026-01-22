# Working Knowledge Base configuration using OpenSearch Serverless

# Data source to reference the existing S3 bucket
# Only used when knowledge_base_bucket_name is provided
data "aws_s3_bucket" "knowledge_base" {
  count  = var.knowledge_base_bucket_name != "" ? 1 : 0
  bucket = var.knowledge_base_bucket_name
}

# S3 bucket for knowledge base (Terraform-managed)
resource "aws_s3_bucket" "knowledge_base_managed" {
  count  = var.knowledge_base_bucket_name == "" ? 1 : 0
  bucket = "${local.s3_prefix}bedrock-kb-${random_id.kb_suffix.hex}"

  tags = {
    Environment = "development"
    Project     = local.full_project_name
    Purpose     = "bedrock-knowledge-base"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "knowledge_base_managed" {
  count  = var.knowledge_base_bucket_name == "" ? 1 : 0
  bucket = aws_s3_bucket.knowledge_base_managed[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload knowledge base files using local-exec provisioner
resource "null_resource" "upload_knowledge_base_files" {
  count = var.knowledge_base_bucket_name == "" ? 1 : 0

  # Trigger re-upload if files change
  triggers = {
    air_quality_file = filemd5("../data/knowledge-base/world_cities_air_quality_water_pollution_2021.csv")
    cost_living_file = filemd5("../data/knowledge-base/world_cities_cost_of_living_2018.csv")
    bucket_name      = aws_s3_bucket.knowledge_base_managed[0].bucket
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "📤 Uploading knowledge base files to ${aws_s3_bucket.knowledge_base_managed[0].bucket}..."
      aws s3 cp ../data/knowledge-base/world_cities_air_quality_water_pollution_2021.csv s3://${aws_s3_bucket.knowledge_base_managed[0].bucket}/world_cities_air_quality_water_pollution_2021.csv
      aws s3 cp ../data/knowledge-base/world_cities_cost_of_living_2018.csv s3://${aws_s3_bucket.knowledge_base_managed[0].bucket}/world_cities_cost_of_living_2018.csv
      echo "✅ Files uploaded successfully"
    EOT
  }

  depends_on = [
    aws_s3_bucket.knowledge_base_managed,
    aws_s3_bucket_versioning.knowledge_base_managed
  ]
}

# Local value to determine which bucket to use
locals {
  knowledge_base_bucket_arn = var.knowledge_base_bucket_name != "" ? data.aws_s3_bucket.knowledge_base[0].arn : aws_s3_bucket.knowledge_base_managed[0].arn
  knowledge_base_bucket_name = var.knowledge_base_bucket_name != "" ? var.knowledge_base_bucket_name : aws_s3_bucket.knowledge_base_managed[0].bucket
}

# OpenSearch Serverless Collection for Knowledge Base
resource "aws_opensearchserverless_collection" "knowledge_base" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${substr(local.full_project_name, 0, 20)}-kb-coll"
  type  = "VECTORSEARCH"

  tags = {
    Environment = "development"
    Project     = local.full_project_name
  }

  depends_on = [
    aws_opensearchserverless_security_policy.knowledge_base_encryption,
    aws_opensearchserverless_security_policy.knowledge_base_network,
    aws_opensearchserverless_access_policy.knowledge_base
  ]
}

# OpenSearch Serverless Access Policy
resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${substr(local.full_project_name, 0, 20)}-kb-access"
  type  = "data"
  
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${substr(local.full_project_name, 0, 20)}-kb-coll"
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
            "index/${substr(local.full_project_name, 0, 20)}-kb-coll/*"
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
      Principal = concat(
        [aws_iam_role.knowledge_base_role.arn],
        var.include_current_user_in_opensearch_access ? [data.aws_caller_identity.current.arn] : []
      )
    }
  ])
}

# OpenSearch Serverless Network Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${substr(local.full_project_name, 0, 20)}-kb-network"
  type  = "network"
  
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${substr(local.full_project_name, 0, 20)}-kb-coll"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${substr(local.full_project_name, 0, 20)}-kb-coll"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch Serverless Encryption Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${substr(local.full_project_name, 0, 18)}-kb-encrypt"
  type  = "encryption"
  
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${substr(local.full_project_name, 0, 20)}-kb-coll"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

# IAM Role for Knowledge Base
resource "aws_iam_role" "knowledge_base_role" {
  name = "${local.full_project_name}-knowledge-base-role"

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
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${local.full_project_name}-knowledge-base-s3-policy"
  role  = aws_iam_role.knowledge_base_role.id

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
          local.knowledge_base_bucket_arn,
          "${local.knowledge_base_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Knowledge Base to access OpenSearch
resource "aws_iam_role_policy" "knowledge_base_opensearch_policy" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${local.full_project_name}-knowledge-base-opensearch-policy"
  role  = aws_iam_role.knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = [
          aws_opensearchserverless_collection.knowledge_base[0].arn
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
          "${aws_opensearchserverless_collection.knowledge_base[0].arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Knowledge Base to access Bedrock models
resource "aws_iam_role_policy" "knowledge_base_bedrock_policy" {
  count = local.deploy_knowledge_base ? 1 : 0
  name  = "${local.full_project_name}-knowledge-base-bedrock-policy"
  role  = aws_iam_role.knowledge_base_role.id

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

# Create OpenSearch vector index automatically
resource "null_resource" "create_opensearch_vector_index" {
  count = local.deploy_knowledge_base ? 1 : 0

  # Trigger recreation if collection changes
  triggers = {
    collection_id = aws_opensearchserverless_collection.knowledge_base[0].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Creating OpenSearch vector index..."
      echo "   Collection ID: ${aws_opensearchserverless_collection.knowledge_base[0].id}"
      
      # Create the vector index
      aws opensearchserverless create-index \
        --id "${aws_opensearchserverless_collection.knowledge_base[0].id}" \
        --index-name "bedrock-knowledge-base-default-index" \
        --index-schema '{
          "settings": {
            "index": {
              "knn": true
            }
          },
          "mappings": {
            "properties": {
              "embeddings": {
                "type": "knn_vector",
                "dimension": 1536,
                "method": {
                  "name": "hnsw",
                  "space_type": "l2",
                  "engine": "faiss"
                }
              },
              "text": {
                "type": "text"
              },
              "bedrock-metadata": {
                "type": "text"
              }
            }
          }
        }' \
        --region us-east-1 || echo "⚠️  Index may already exist"
      
      echo "✅ Vector index creation completed"
      
      # Wait for index to be ready
      echo "⏳ Waiting for index to be ready..."
      sleep 10
    EOT
  }

  depends_on = [
    aws_opensearchserverless_collection.knowledge_base,
    aws_opensearchserverless_access_policy.knowledge_base
  ]
}

# Bedrock Knowledge Base with OpenSearch Serverless
resource "aws_bedrockagent_knowledge_base" "city_facts" {
  count    = local.deploy_knowledge_base ? 1 : 0
  name     = "${local.full_project_name}-city-facts-kb"
  role_arn = aws_iam_role.knowledge_base_role.arn
  
  description = "Knowledge base containing city facts, air quality, and cost of living data"

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base[0].arn
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
    Project     = local.full_project_name
  }

  depends_on = [
    null_resource.upload_knowledge_base_files,
    null_resource.create_opensearch_vector_index
  ]
}

# Data Source 1: Air Quality and Water Pollution CSV
resource "aws_bedrockagent_data_source" "air_quality_data_simple" {
  count             = local.deploy_knowledge_base ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.city_facts[0].id
  name              = "city-air-quality-water-pollution"
  description       = "World cities air quality and water pollution data from 2021"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = local.knowledge_base_bucket_arn
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
  count             = local.deploy_knowledge_base ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.city_facts[0].id
  name              = "city-cost-of-living"
  description       = "World cities cost of living data from 2018"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = local.knowledge_base_bucket_arn
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
  count                = local.deploy_knowledge_base ? 1 : 0
  agent_id             = aws_bedrockagent_agent.city_facts_agent.agent_id
  agent_version        = "DRAFT"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.city_facts[0].id
  description          = "Association between city facts agent and knowledge base"
  knowledge_base_state = "ENABLED"
}