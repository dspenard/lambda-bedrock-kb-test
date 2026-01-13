#!/bin/bash

# Development workflow helper
# Usage: ./dev-workflow.sh [command]

set -e

show_help() {
  echo "🛠️  Development Workflow Helper"
  echo ""
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
  echo "  setup-kb-s3   - Create S3 bucket for knowledge base"
  echo "  check-kb-s3   - Check knowledge base S3 bucket status"
  echo "  cleanup-kb-s3 - Delete knowledge base S3 bucket (legacy)"
  echo "  teardown      - Complete infrastructure teardown"
  echo "  teardown-infra - Infrastructure-only teardown"
  echo "  teardown-s3   - S3-only teardown"
  echo ""
  echo "Examples:"
  echo "  ./dev-workflow.sh deploy-direct"
  echo "  ./dev-workflow.sh test Tokyo"
  echo "  ./dev-workflow.sh logs-direct"
  echo "  ./dev-workflow.sh teardown-infra"
  echo "  ./dev-workflow.sh setup-kb-s3"
}

show_status() {
  echo "📊 Current Deployment Status"
  echo ""
  
  echo "🔍 Lambda Functions:"
  aws lambda list-functions --query 'Functions[?contains(FunctionName, `bedrock-agent-testbed`)].{Name:FunctionName,Runtime:Runtime,LastModified:LastModified}' --output table
  
  echo ""
  echo "🤖 Bedrock Agent:"
  aws bedrock-agent get-agent --agent-id 1DSXPQRXQJ --query 'agent.{Name:agentName,Status:agentStatus,Model:foundationModel}' --output table
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
    ./build.sh
    ;;
  
  "deploy")
    ./deploy-lambda.sh both
    ;;
  
  "deploy-direct")
    ./deploy-direct.sh
    ;;
  
  "deploy-agent")
    ./deploy-agent.sh
    ;;
  
  "test")
    ./test-lambda.sh both ${2:-Tokyo}
    ;;
  
  "test-direct")
    ./test-lambda.sh direct ${2:-Tokyo}
    ;;
  
  "test-agent")
    ./test-lambda.sh agent ${2:-Tokyo}
    ;;
  
  "logs-direct")
    show_logs "/aws/lambda/bedrock-agent-testbed-city-facts-direct" "direct"
    ;;
  
  "logs-agent")
    show_logs "/aws/lambda/bedrock-agent-testbed-city-facts-agent" "agent"
    ;;
  
  "terraform")
    echo "🏗️  Running Terraform..."
    terraform plan
    read -p "Apply changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      terraform apply
    fi
    ;;
  
  "status")
    show_status
    ;;
  
  "setup-kb-s3")
    ./setup-knowledge-base-s3.sh
    ;;
  
  "check-kb-s3")
    ./check-knowledge-base-s3.sh
    ;;
  
  "cleanup-kb-s3")
    ./cleanup-knowledge-base-s3.sh
    ;;
  
  "teardown")
    ./teardown-complete.sh
    ;;
  
  "teardown-infra")
    ./teardown-infrastructure.sh
    ;;
  
  "teardown-s3")
    ./teardown-s3-only.sh
    ;;
  
  "help"|*)
    show_help
    ;;
esac