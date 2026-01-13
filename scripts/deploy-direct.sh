#!/bin/bash

# Deploy only the direct model access Lambda function
# Usage: ./deploy-direct.sh

set -e

echo "🚀 Deploying direct model access Lambda..."

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

# Build only the direct Lambda
echo "📦 Building direct Lambda package..."
mkdir -p build_direct
cp src/lambda_direct/index.py build_direct/
cd build_direct
zip -r ../city_facts_direct.zip .
cd ..
rm -rf build_direct

echo "🔄 Updating Lambda function..."
aws lambda update-function-code \
  --function-name ${FULL_PROJECT_NAME}-city-facts-direct \
  --zip-file fileb://city_facts_direct.zip

echo "✅ Direct Lambda updated successfully!"
echo ""
echo "💡 Test: aws lambda invoke --function-name ${FULL_PROJECT_NAME}-city-facts-direct --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Tokyo\"}' response.json"