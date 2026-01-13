#!/bin/bash

# Deploy only the agent-based Lambda function
# Usage: ./deploy-agent.sh

set -e

echo "🚀 Deploying agent-based Lambda..."

# Build only the agent Lambda
echo "📦 Building agent Lambda package..."
mkdir -p build_agent
cp lambda_agent_src/index.py build_agent/
cd build_agent
zip -r ../city_facts_agent.zip .
cd ..
rm -rf build_agent

echo "🔄 Updating Lambda function..."
aws lambda update-function-code \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --zip-file fileb://city_facts_agent.zip

echo "✅ Agent Lambda updated successfully!"
echo ""
echo "💡 Test: aws lambda invoke --function-name bedrock-agent-testbed-city-facts-agent --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Paris\"}' response.json"