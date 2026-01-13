#!/bin/bash

# Deploy Lambda functions without running Terraform
# Usage: ./deploy-lambda.sh [direct|agent|both]

set -e

FUNCTION_TYPE=${1:-both}

echo "🚀 Deploying Lambda functions..."

# Build the Lambda packages
echo "📦 Building Lambda packages..."
./build.sh

case $FUNCTION_TYPE in
  "direct")
    echo "🔄 Updating direct model access Lambda..."
    aws lambda update-function-code \
      --function-name bedrock-agent-testbed-city-facts-direct \
      --zip-file fileb://city_facts_direct.zip
    echo "✅ Direct Lambda updated successfully!"
    ;;
  
  "agent")
    echo "🔄 Updating agent-based Lambda..."
    aws lambda update-function-code \
      --function-name bedrock-agent-testbed-city-facts-agent \
      --zip-file fileb://city_facts_agent.zip
    echo "✅ Agent Lambda updated successfully!"
    ;;
  
  "both"|*)
    echo "🔄 Updating both Lambda functions..."
    
    echo "  → Updating direct model access Lambda..."
    aws lambda update-function-code \
      --function-name bedrock-agent-testbed-city-facts-direct \
      --zip-file fileb://city_facts_direct.zip
    
    echo "  → Updating agent-based Lambda..."
    aws lambda update-function-code \
      --function-name bedrock-agent-testbed-city-facts-agent \
      --zip-file fileb://city_facts_agent.zip
    
    echo "✅ Both Lambda functions updated successfully!"
    ;;
esac

echo ""
echo "🎉 Lambda deployment complete!"
echo ""
echo "💡 Test your functions:"
echo "   Direct:  aws lambda invoke --function-name bedrock-agent-testbed-city-facts-direct --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Tokyo\"}' response.json"
echo "   Agent:   aws lambda invoke --function-name bedrock-agent-testbed-city-facts-agent --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Paris\"}' response.json"