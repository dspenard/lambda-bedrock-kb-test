#!/bin/bash

# Deploy only the agent-based Lambda function
# Usage: ./deploy-agent.sh

set -e

echo "🚀 Deploying agent-based Lambda..."

# Detect prefix from terraform.tfvars if it exists
PREFIX=""
FULL_PROJECT_NAME="bedrock-agent-testbed"

if [ -f "terraform/terraform.tfvars" ]; then
    PREFIX=$(grep -E '^resource_prefix\s*=' terraform/terraform.tfvars 2>/dev/null | sed 's/.*=\s*"\([^"]*\)".*/\1/' || echo "")
    if [ -n "$PREFIX" ]; then
        FULL_PROJECT_NAME="${PREFIX}-bedrock-agent-testbed"
        echo "🏷️  Detected prefix: $PREFIX"
        echo "   Using project name: $FULL_PROJECT_NAME"
    fi
fi

# Build only the agent Lambda
echo "📦 Building agent Lambda package..."
mkdir -p build_agent
cp src/lambda_agent/index.py build_agent/
cd build_agent
zip -r ../city_facts_agent.zip .
cd ..
rm -rf build_agent

echo "🔄 Updating Lambda function..."
aws lambda update-function-code \
  --function-name ${FULL_PROJECT_NAME}-city-facts-agent \
  --zip-file fileb://city_facts_agent.zip

echo "✅ Agent Lambda updated successfully!"
echo ""
echo "💡 Test: aws lambda invoke --function-name ${FULL_PROJECT_NAME}-city-facts-agent --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Paris\"}' response.json"