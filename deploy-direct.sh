#!/bin/bash

# Deploy only the direct model access Lambda function
# Usage: ./deploy-direct.sh

set -e

echo "🚀 Deploying direct model access Lambda..."

# Build only the direct Lambda
echo "📦 Building direct Lambda package..."
mkdir -p build_direct
cp lambda_src/index.py build_direct/
cd build_direct
zip -r ../city_facts_direct.zip .
cd ..
rm -rf build_direct

echo "🔄 Updating Lambda function..."
aws lambda update-function-code \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --zip-file fileb://city_facts_direct.zip

echo "✅ Direct Lambda updated successfully!"
echo ""
echo "💡 Test: aws lambda invoke --function-name bedrock-agent-testbed-city-facts-direct --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Tokyo\"}' response.json"