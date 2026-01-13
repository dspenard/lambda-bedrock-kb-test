#!/bin/bash

# Deploy Lambda functions without running Terraform
# Usage: ./deploy-lambda.sh [direct|agent|both]
# Automatically detects resource prefix from terraform.tfvars

set -e

FUNCTION_TYPE=${1:-both}

echo "🚀 Deploying Lambda functions..."

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

# Build the Lambda packages
echo "📦 Building Lambda packages..."
./scripts/build.sh

case $FUNCTION_TYPE in
  "direct")
    echo "🔄 Updating direct model access Lambda..."
    aws lambda update-function-code \
      --function-name ${FULL_PROJECT_NAME}-city-facts-direct \
      --zip-file fileb://city_facts_direct.zip
    echo "✅ Direct Lambda updated successfully!"
    ;;
  
  "agent")
    echo "🔄 Updating agent-based Lambda..."
    aws lambda update-function-code \
      --function-name ${FULL_PROJECT_NAME}-city-facts-agent \
      --zip-file fileb://city_facts_agent.zip
    echo "✅ Agent Lambda updated successfully!"
    ;;
  
  "both"|*)
    echo "🔄 Updating both Lambda functions..."
    
    echo "  → Updating direct model access Lambda..."
    aws lambda update-function-code \
      --function-name ${FULL_PROJECT_NAME}-city-facts-direct \
      --zip-file fileb://city_facts_direct.zip
    
    echo "  → Updating agent-based Lambda..."
    aws lambda update-function-code \
      --function-name ${FULL_PROJECT_NAME}-city-facts-agent \
      --zip-file fileb://city_facts_agent.zip
    
    echo "✅ Both Lambda functions updated successfully!"
    ;;
esac

echo ""
echo "🎉 Lambda deployment complete!"
echo ""
echo "💡 Test your functions:"
echo "   Direct:  aws lambda invoke --function-name ${FULL_PROJECT_NAME}-city-facts-direct --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Tokyo\"}' response.json"
echo "   Agent:   aws lambda invoke --function-name ${FULL_PROJECT_NAME}-city-facts-agent --cli-binary-format raw-in-base64-out --payload '{\"city\": \"Paris\"}' response.json"