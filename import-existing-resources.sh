#!/bin/bash

# Script to import existing AWS resources back into Terraform state
# This recovers from accidentally deleted terraform.tfstate files

set -e

echo "🔄 Importing existing AWS resources into Terraform state..."
echo ""

# First, we need to get the S3 bucket name that was created
echo "📋 Getting S3 bucket name..."
BUCKET_NAME=$(aws s3 ls | grep "bedrock-kb-" | awk '{print $3}' | head -1)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Could not find S3 bucket with bedrock-kb- prefix"
    echo "   Please run ./setup-knowledge-base-s3.sh first"
    exit 1
fi

echo "   Found bucket: $BUCKET_NAME"
echo "$BUCKET_NAME" > .kb-bucket-name
echo "knowledge_base_bucket_name = \"$BUCKET_NAME\"" > terraform.tfvars

# Initialize Terraform
echo ""
echo "🏗️ Initializing Terraform..."
terraform init

echo ""
echo "📥 Importing Lambda functions..."
terraform import aws_lambda_function.city_facts_direct bedrock-agent-testbed-city-facts-direct
terraform import aws_lambda_function.city_facts_agent bedrock-agent-testbed-city-facts-agent

echo ""
echo "📥 Importing CloudWatch log groups..."
terraform import aws_cloudwatch_log_group.lambda_logs_direct /aws/lambda/bedrock-agent-testbed-city-facts-direct
terraform import aws_cloudwatch_log_group.lambda_logs_agent /aws/lambda/bedrock-agent-testbed-city-facts-agent

echo ""
echo "📥 Importing IAM roles..."
terraform import aws_iam_role.lambda_role bedrock-agent-testbed-lambda-role
terraform import aws_iam_role.bedrock_agent_role bedrock-agent-testbed-bedrock-agent-role
terraform import aws_iam_role.knowledge_base_role bedrock-agent-testbed-knowledge-base-role

echo ""
echo "📥 Importing IAM policies..."
terraform import aws_iam_role_policy.bedrock_policy bedrock-agent-testbed-lambda-role:bedrock-agent-testbed-bedrock-policy
terraform import aws_iam_role_policy.bedrock_agent_model_policy bedrock-agent-testbed-bedrock-agent-role:bedrock-agent-testbed-bedrock-agent-model-policy
terraform import aws_iam_role_policy.knowledge_base_s3_policy bedrock-agent-testbed-knowledge-base-role:bedrock-agent-testbed-knowledge-base-s3-policy
terraform import aws_iam_role_policy.knowledge_base_opensearch_policy bedrock-agent-testbed-knowledge-base-role:bedrock-agent-testbed-knowledge-base-opensearch-policy
terraform import aws_iam_role_policy.knowledge_base_bedrock_policy bedrock-agent-testbed-knowledge-base-role:bedrock-agent-testbed-knowledge-base-bedrock-policy

echo ""
echo "📥 Importing IAM policy attachment..."
terraform import aws_iam_role_policy_attachment.lambda_logs bedrock-agent-testbed-lambda-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo ""
echo "📥 Importing Bedrock agent..."
terraform import aws_bedrockagent_agent.city_facts_agent 1DSXPQRXQJ

echo ""
echo "📥 Importing Lambda permission..."
terraform import aws_lambda_permission.allow_bedrock_agent AllowBedrockAgentInvoke

echo ""
echo "📥 Importing OpenSearch Serverless resources..."
# Get collection ID
COLLECTION_ID=$(aws opensearchserverless list-collections --query 'collectionSummaries[?contains(name, `bedrock-agent-testbe-kb-coll`)].id' --output text)
echo "   Collection ID: $COLLECTION_ID"

terraform import aws_opensearchserverless_collection.knowledge_base $COLLECTION_ID
terraform import aws_opensearchserverless_security_policy.knowledge_base_encryption bedrock-agent-test-kb-encrypt
terraform import aws_opensearchserverless_security_policy.knowledge_base_network bedrock-agent-testbe-kb-network
terraform import aws_opensearchserverless_access_policy.knowledge_base bedrock-agent-testbe-kb-access

echo ""
echo "📥 Importing Knowledge Base..."
terraform import 'aws_bedrockagent_knowledge_base.city_facts_simple[0]' FKTBSOTLZL

echo ""
echo "📥 Importing Data Sources..."
# Get data source IDs
AIR_QUALITY_DS=$(aws bedrock-agent list-data-sources --knowledge-base-id FKTBSOTLZL --query 'dataSourceSummaries[?contains(name, `air-quality`)].dataSourceId' --output text)
COST_LIVING_DS=$(aws bedrock-agent list-data-sources --knowledge-base-id FKTBSOTLZL --query 'dataSourceSummaries[?contains(name, `cost-of-living`)].dataSourceId' --output text)

echo "   Air Quality Data Source ID: $AIR_QUALITY_DS"
echo "   Cost of Living Data Source ID: $COST_LIVING_DS"

terraform import "aws_bedrockagent_data_source.air_quality_data_simple[0]" "$AIR_QUALITY_DS,FKTBSOTLZL"
terraform import "aws_bedrockagent_data_source.cost_of_living_data_simple[0]" "$COST_LIVING_DS,FKTBSOTLZL"

echo ""
echo "📥 Importing Knowledge Base Association..."
terraform import 'aws_bedrockagent_agent_knowledge_base_association.city_facts_kb_association_simple[0]' 1DSXPQRXQJ,DRAFT,FKTBSOTLZL

echo ""
echo "📥 Importing Action Group..."
ACTION_GROUP_ID=$(aws bedrock-agent list-agent-action-groups --agent-id 1DSXPQRXQJ --agent-version DRAFT --query 'actionGroupSummaries[0].actionGroupId' --output text)
echo "   Action Group ID: $ACTION_GROUP_ID"
terraform import aws_bedrockagent_agent_action_group.city_facts_action_group "$ACTION_GROUP_ID,1DSXPQRXQJ,DRAFT"

echo ""
echo "📥 Importing Random ID..."
terraform import random_id.kb_suffix $(echo -n "PmjOMA" | base64 -d | xxd -p)

echo ""
echo "🎉 Import complete! Running terraform plan to verify..."
terraform plan

echo ""
echo "✅ All resources have been imported back into Terraform state!"
echo "   Your infrastructure is now managed by Terraform again."
echo ""
echo "💡 Next steps:"
echo "   1. Review the terraform plan output above"
echo "   2. If everything looks good, you can continue using Terraform normally"
echo "   3. The .kb-bucket-name and terraform.tfvars files have been recreated"