#!/bin/bash

# Test Lambda functions
# Usage: ./test-lambda.sh [direct|agent|both] [city_name]

set -e

FUNCTION_TYPE=${1:-both}
CITY_NAME=${2:-Tokyo}

echo "🧪 Testing Lambda functions with city: $CITY_NAME"

test_function() {
  local func_name=$1
  local func_type=$2
  local output_file="test_${func_type}_$(date +%s).json"
  
  echo "  → Testing $func_type function..."
  
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
  fi
  echo ""
}

case $FUNCTION_TYPE in
  "direct")
    test_function "bedrock-agent-testbed-city-facts-direct" "direct"
    ;;
  
  "agent")
    test_function "bedrock-agent-testbed-city-facts-agent" "agent"
    ;;
  
  "both"|*)
    test_function "bedrock-agent-testbed-city-facts-direct" "direct"
    test_function "bedrock-agent-testbed-city-facts-agent" "agent"
    ;;
esac

echo "🎉 Testing complete!"