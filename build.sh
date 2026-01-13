#!/bin/bash

# Build script for Lambda functions
echo "Building Lambda functions..."

# Create build directory
mkdir -p build_direct build_agent

# Build direct model access Lambda
echo "Building direct model access Lambda..."
cp lambda_src/index.py build_direct/
cd build_direct
zip -r ../city_facts_direct.zip .
cd ..

# Build agent-based Lambda
echo "Building agent-based Lambda..."
cp lambda_agent_src/index.py build_agent/
cd build_agent
zip -r ../city_facts_agent.zip .
cd ..

# Clean up build directories
rm -rf build_direct build_agent

echo "Lambda functions packaged:"
echo "- city_facts_direct.zip (direct model access)"
echo "- city_facts_agent.zip (Bedrock agent)"