#!/bin/bash

# Test Lambda functions with automatic prefix detection
# Usage: ./test-lambda.sh [direct|agent|both] [city_name]

set -e

FUNCTION_TYPE=${1:-both}
CITY_NAME=${2:-Tokyo}

echo "🧪 Testing Lambda functions with city: $CITY_NAME"

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

test_function() {
  local func_name=$1
  local func_type=$2
  local output_file="test_${func_type}_$(date +%s).json"
  
  echo "  → Testing $func_type function: $func_name"
  
  aws lambda invoke \
    --function-name "$func_name" \
    --cli-binary-format raw-in-base64-out \
    --payload "{\"city\": \"$CITY_NAME\"}" \
    "$output_file" > /dev/null
  
  if [ $? -eq 0 ]; then
    echo "    ✅ Function invoked successfully"
    echo "    📄 Response saved to: $output_file"
    
    # Show formatted response
    echo "    📋 Response preview:"
    if command -v jq &> /dev/null; then
      cat "$output_file" | jq -r '.body' | jq . | head -10
      echo "    ..."
    else
      echo "    $(cat "$output_file" | head -c 200)..."
    fi
  else
    echo "    ❌ Function invocation failed"
    echo "    💡 Make sure the function exists and you have proper AWS permissions"
  fi
  echo ""
}

case $FUNCTION_TYPE in
  "direct")
    test_function "${FULL_PROJECT_NAME}-city-facts-direct" "direct"
    ;;
  
  "agent")
    test_function "${FULL_PROJECT_NAME}-city-facts-agent" "agent"
    ;;
  
  "both"|*)
    test_function "${FULL_PROJECT_NAME}-city-facts-direct" "direct"
    test_function "${FULL_PROJECT_NAME}-city-facts-agent" "agent"
    ;;
esac

echo "🎉 Testing complete!"
echo ""
echo "💡 Recommended test cities with knowledge base data:"
echo "   Geneva, Berlin, Tokyo, London, Paris, Boston, Chicago, Los Angeles"