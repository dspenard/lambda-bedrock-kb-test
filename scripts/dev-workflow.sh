#!/bin/bash

# Development workflow helper
# Usage: ./dev-workflow.sh [command]

set -e

# Detect prefix from terraform.tfvars if it exists
PREFIX=""
FULL_PROJECT_NAME="bedrock-agent-testbed"

if [ -f "terraform/terraform.tfvars" ]; then
    PREFIX=$(grep -E '^resource_prefix\s*=' terraform/terraform.tfvars 2>/dev/null | sed 's/.*=\s*"\([^"]*\)".*/\1/' || echo "")
    if [ -n "$PREFIX" ]; then
        FULL_PROJECT_NAME="${PREFIX}-bedrock-agent-testbed"
    fi
fi

show_help() {
  echo "🛠️  Development Workflow Helper"
  echo ""
  if [ -n "$PREFIX" ]; then
    echo "🏷️  Detected prefix: $PREFIX (resources: ${FULL_PROJECT_NAME}-*)"
    echo ""
  fi
  echo "Commands:"
  echo "  build         - Build Lambda packages only"
  echo "  deploy        - Deploy both Lambda functions"
  echo "  deploy-direct - Deploy only direct model Lambda"
  echo "  deploy-agent  - Deploy only agent-based Lambda"
  echo "  test          - Test both Lambda functions"
  echo "  test-direct   - Test only direct model Lambda"
  echo "  test-agent    - Test only agent-based Lambda"
  echo "  logs-direct   - Show recent logs for direct Lambda"
  echo "  logs-agent    - Show recent logs for agent Lambda"
  echo "  terraform     - Run terraform plan and apply"
  echo "  status        - Show current deployment status"
  echo "  teardown      - Complete infrastructure teardown"
  echo "  teardown-infra - Infrastructure-only teardown"
  echo "  teardown-s3   - S3-only teardown"
  echo ""
  echo "Legacy S3 Commands (for external bucket management):"
  echo "  setup-kb-s3   - Create S3 bucket for knowledge base (legacy)"
  echo "  check-kb-s3   - Check knowledge base S3 bucket status"
  echo ""
  echo "Examples:"
  echo "  ./scripts/dev-workflow.sh deploy-direct"
  echo "  ./scripts/dev-workflow.sh test Geneva"
  echo "  ./scripts/dev-workflow.sh logs-direct"
  echo "  ./scripts/dev-workflow.sh teardown-infra"
  echo ""
  echo "💡 Note: New deployments use Terraform-managed S3 buckets automatically"
}

show_status() {
  echo "📊 Current Deployment Status"
  echo ""
  
  if [ -n "$PREFIX" ]; then
    echo "🏷️  Using prefix: $PREFIX"
    echo ""
  fi
  
  echo "🔍 Lambda Functions:"
  aws lambda list-functions --query "Functions[?contains(FunctionName, \`${FULL_PROJECT_NAME}\`)].{Name:FunctionName,Runtime:Runtime,LastModified:LastModified}" --output table
  
  echo ""
  echo "🤖 Bedrock Agents:"
  aws bedrock-agent list-agents --query "agentSummaries[?contains(agentName, \`${FULL_PROJECT_NAME}\`)].{Name:agentName,Status:agentStatus,ID:agentId}" --output table
  
  echo ""
  echo "🧠 Knowledge Bases:"
  aws bedrock-agent list-knowledge-bases --query "knowledgeBaseSummaries[?contains(name, \`${FULL_PROJECT_NAME}\`)].{Name:name,Status:status,ID:knowledgeBaseId}" --output table
  
  echo ""
  echo "🪣 S3 Buckets:"
  if [ -n "$PREFIX" ]; then
    aws s3 ls | grep "${PREFIX}-bedrock-kb-" || echo "No S3 buckets found with prefix ${PREFIX}-bedrock-kb-"
  else
    aws s3 ls | grep "bedrock-kb-" || echo "No S3 buckets found with bedrock-kb- pattern"
  fi
}

show_logs() {
  local log_group=$1
  local function_name=$2
  
  echo "📋 Recent logs for $function_name:"
  
  # Get the most recent log stream
  local log_stream=$(aws logs describe-log-streams \
    --log-group-name "$log_group" \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text)
  
  if [ "$log_stream" != "None" ] && [ "$log_stream" != "" ]; then
    aws logs get-log-events \
      --log-group-name "$log_group" \
      --log-stream-name "$log_stream" \
      --query 'events[-10:].message' \
      --output text
  else
    echo "No recent logs found"
  fi
}

COMMAND=${1:-help}

case $COMMAND in
  "build")
    ./scripts/build.sh
    ;;
  
  "deploy")
    ./scripts/deploy-lambda.sh both
    ;;
  
  "deploy-direct")
    ./scripts/deploy-direct.sh
    ;;
  
  "deploy-agent")
    ./scripts/deploy-agent.sh
    ;;
  
  "test")
    ./scripts/test-lambda.sh both ${2:-Geneva}
    ;;
  
  "test-direct")
    ./scripts/test-lambda.sh direct ${2:-Geneva}
    ;;
  
  "test-agent")
    ./scripts/test-lambda.sh agent ${2:-Geneva}
    ;;
  
  "logs-direct")
    show_logs "/aws/lambda/${FULL_PROJECT_NAME}-city-facts-direct" "direct"
    ;;
  
  "logs-agent")
    show_logs "/aws/lambda/${FULL_PROJECT_NAME}-city-facts-agent" "agent"
    ;;
  
  "terraform")
    echo "🏗️  Running Terraform..."
    cd terraform
    terraform plan
    read -p "Apply changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      terraform apply
    fi
    cd ..
    ;;
  
  "status")
    show_status
    ;;
  
  "setup-kb-s3")
    echo "⚠️  Note: This is a legacy command for external S3 bucket management."
    echo "   New deployments use Terraform-managed S3 buckets automatically."
    echo "   Set enable_knowledge_base = true in terraform.tfvars instead."
    echo ""
    read -p "Continue with legacy S3 setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      ./scripts/setup-knowledge-base-s3.sh
    fi
    ;;
  
  "check-kb-s3")
    ./scripts/check-knowledge-base-s3.sh
    ;;
  
  "teardown")
    ./scripts/teardown-complete.sh
    ;;
  
  "teardown-infra")
    ./scripts/teardown-infrastructure.sh
    ;;
  
  "teardown-s3")
    ./scripts/teardown-s3-only.sh
    ;;
  
  "help"|*)
    show_help
    ;;
esac