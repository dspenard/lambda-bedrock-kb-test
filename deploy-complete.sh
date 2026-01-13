#!/bin/bash

# Complete Deployment Script for Bedrock Agent Test Bed with Knowledge Base
# This script automates the entire deployment process

set -e

echo "🚀 Starting complete deployment of Bedrock Agent Test Bed with Knowledge Base..."
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command_exists terraform; then
    echo "❌ Error: Terraform is not installed"
    exit 1
fi

if ! command_exists aws; then
    echo "❌ Error: AWS CLI is not installed"
    exit 1
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ Error: AWS CLI is not configured or credentials are invalid"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Step 1: Initialize Terraform
echo "📦 Step 1: Initializing Terraform..."
terraform init
echo "✅ Terraform initialized"
echo ""

# Step 2: Deploy core infrastructure
echo "🏗️  Step 2: Deploying core infrastructure (Lambda, IAM, Bedrock Agent)..."
terraform apply -auto-approve
echo "✅ Core infrastructure deployed"
echo ""

# Step 3: Setup S3 bucket for knowledge base
echo "📁 Step 3: Setting up S3 bucket for knowledge base..."
if [ -f "./setup-knowledge-base-s3.sh" ]; then
    ./setup-knowledge-base-s3.sh
else
    echo "❌ Error: setup-knowledge-base-s3.sh not found"
    exit 1
fi
echo "✅ S3 bucket setup completed"
echo ""

# Step 4: Deploy OpenSearch collection
echo "🔍 Step 4: Deploying OpenSearch Serverless collection..."
terraform apply -auto-approve
echo "✅ OpenSearch collection deployed"
echo ""

# Step 5: Create OpenSearch vector index (the manual step)
echo "⚙️  Step 5: Creating OpenSearch vector index..."
if [ -f "./create-opensearch-index.sh" ]; then
    ./create-opensearch-index.sh
else
    echo "❌ Error: create-opensearch-index.sh not found"
    exit 1
fi
echo "✅ OpenSearch vector index created"
echo ""

# Step 6: Deploy knowledge base
echo "🧠 Step 6: Deploying Bedrock Knowledge Base..."
terraform apply -auto-approve
echo "✅ Knowledge base deployed"
echo ""

# Step 7: Ingest knowledge base data
echo "📊 Step 7: Ingesting knowledge base data..."

# Get IDs from Terraform output
KB_ID=$(terraform output -raw knowledge_base_id)
DS1_ID=$(terraform output -raw air_quality_data_source_id)
DS2_ID=$(terraform output -raw cost_of_living_data_source_id)

echo "   Knowledge Base ID: $KB_ID"
echo "   Air Quality Data Source ID: $DS1_ID"
echo "   Cost of Living Data Source ID: $DS2_ID"

# Start first ingestion job
echo "   🔄 Starting air quality data ingestion..."
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id "$KB_ID" \
  --data-source-id "$DS1_ID" \
  --description "Initial ingestion of air quality data" \
  --region us-east-1 > /dev/null

# Wait for first job to complete
echo "   ⏳ Waiting for air quality ingestion to complete..."
while true; do
    STATUS=$(aws bedrock-agent list-ingestion-jobs \
      --knowledge-base-id "$KB_ID" \
      --data-source-id "$DS1_ID" \
      --region us-east-1 \
      --query 'ingestionJobSummaries[0].status' \
      --output text)
    
    if [ "$STATUS" = "COMPLETE" ]; then
        echo "   ✅ Air quality data ingestion completed"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "   ❌ Air quality data ingestion failed"
        exit 1
    fi
    
    sleep 5
done

# Start second ingestion job
echo "   🔄 Starting cost of living data ingestion..."
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id "$KB_ID" \
  --data-source-id "$DS2_ID" \
  --description "Initial ingestion of cost of living data" \
  --region us-east-1 > /dev/null

# Wait for second job to complete
echo "   ⏳ Waiting for cost of living ingestion to complete..."
while true; do
    STATUS=$(aws bedrock-agent list-ingestion-jobs \
      --knowledge-base-id "$KB_ID" \
      --data-source-id "$DS2_ID" \
      --region us-east-1 \
      --query 'ingestionJobSummaries[0].status' \
      --output text)
    
    if [ "$STATUS" = "COMPLETE" ]; then
        echo "   ✅ Cost of living data ingestion completed"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "   ❌ Cost of living data ingestion failed"
        exit 1
    fi
    
    sleep 5
done

echo "✅ All data ingestion completed"
echo ""

# Step 8: Test the deployment
echo "🧪 Step 8: Testing the deployment..."

AGENT_FUNCTION=$(terraform output -raw lambda_function_agent_name)
DIRECT_FUNCTION=$(terraform output -raw lambda_function_direct_name)

echo "   Testing direct Lambda function..."
aws lambda invoke \
  --function-name "$DIRECT_FUNCTION" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Tokyo"}' \
  test_direct_result.json > /dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ Direct Lambda test passed"
else
    echo "   ❌ Direct Lambda test failed"
fi

echo "   Testing agent Lambda function with knowledge base..."
aws lambda invoke \
  --function-name "$AGENT_FUNCTION" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "New York City"}' \
  test_agent_result.json > /dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ Agent Lambda test passed"
else
    echo "   ❌ Agent Lambda test failed"
fi

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo ""
echo "📋 Summary:"
echo "   • Lambda Functions: ✅ Deployed and tested"
echo "   • Bedrock Agent: ✅ Created with action groups"
echo "   • Knowledge Base: ✅ Created with OpenSearch Serverless"
echo "   • Data Sources: ✅ Ingested (air quality + cost of living)"
echo "   • S3 Bucket: ✅ Created and populated"
echo ""
echo "🧪 Test Commands:"
echo "   # Test direct model access:"
echo "   aws lambda invoke --function-name $DIRECT_FUNCTION --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Geneva\"}' response.json"
echo ""
echo "   # Test agent with knowledge base:"
echo "   aws lambda invoke --function-name $AGENT_FUNCTION --cli-binary-format raw-in-base64-out --payload '{\"city\": \"New York City\"}' response.json"
echo ""
echo "   # Use helper scripts:"
echo "   ./test-lambda.sh both Tokyo"
echo "   ./dev-workflow.sh test Berlin"
echo ""
echo "📊 Terraform Outputs:"
terraform output
echo ""
echo "✨ Your Bedrock Agent Test Bed with Knowledge Base is ready to use!"