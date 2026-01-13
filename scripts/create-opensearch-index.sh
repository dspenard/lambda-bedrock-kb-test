#!/bin/bash

# Create OpenSearch Serverless Vector Index for Bedrock Knowledge Base
# This script automates the manual step required for knowledge base setup

set -e

echo "🔍 Creating OpenSearch Serverless Vector Index..."

# Get the collection ID from Terraform output
COLLECTION_ID=$(terraform output -raw opensearch_collection_id 2>/dev/null || echo "")

if [ -z "$COLLECTION_ID" ]; then
    echo "❌ Error: Could not get OpenSearch collection ID from Terraform output"
    echo "   Make sure you've run 'terraform apply' to create the OpenSearch collection first"
    exit 1
fi

echo "📋 Using OpenSearch Collection ID: $COLLECTION_ID"

# Create the vector index
echo "🚀 Creating vector index 'bedrock-knowledge-base-default-index'..."

aws opensearchserverless create-index \
  --id "$COLLECTION_ID" \
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
  --region us-east-1

echo "✅ Vector index created successfully!"

# Verify the index was created
echo "🔍 Verifying index creation..."
sleep 2

aws opensearchserverless get-index \
  --id "$COLLECTION_ID" \
  --index-name "bedrock-knowledge-base-default-index" \
  --region us-east-1 > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Index verification successful!"
    echo ""
    echo "🎉 OpenSearch vector index is ready!"
    echo "   You can now run 'terraform apply' to create the knowledge base."
else
    echo "❌ Index verification failed"
    exit 1
fi