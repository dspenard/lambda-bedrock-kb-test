# Developer Guide

Comprehensive guide for developers working with the Bedrock Agent Test Bed project.

## 📚 Table of Contents

- [Project Structure](#-project-structure)
- [Current Components](#-current-components)
- [Knowledge Base Data Sources](#-knowledge-base-data-sources)
- [Development Workflow](#️-development-workflow)
- [Example Responses](#-example-responses)
- [Troubleshooting](#-troubleshooting)
- [Quick Reference](#-quick-reference)
- [Contributing](#-contributing)

---

## 📁 Project Structure

### 🔑 Key Files and Folders

**📁 terraform/** - Infrastructure as Code
- All Terraform configuration files
- Your personal `terraform.tfvars` settings (optional - has defaults)
- **CRITICAL**: `terraform.tfstate` file (never delete!)
  - **💡 Production Tip**: Use [Terraform remote state](https://developer.hashicorp.com/terraform/language/state/remote) (e.g. S3 backend with DynamoDB locking) for team environments and production deployments to prevent state file loss and enable collaboration

**📁 scripts/** - Automation and Management
- All deployment, testing, and teardown scripts
- Auto-detect resource prefixes from terraform.tfvars
- Run from project root: `./scripts/deploy-complete.sh`

**📁 src/** - Lambda Source Code
- Organized by function type
- `lambda_direct/` - Direct model access
- `lambda_agent/` - Agent-based approach

**📁 data/** - Test Data and Knowledge Base
- `lambda-tests/` - JSON payloads for testing
- `knowledge-base/` - CSV files for vector database

**📁 docs/** - Documentation
- `API.md` - Complete API documentation with OpenAPI specifications
- `DEVELOPER_GUIDE.md` - This file
- `bedrock-full-comparison.png` - Architecture diagram


```
.
├── terraform/                        # 🏗️ Infrastructure as Code
│   ├── main.tf                       # Main Terraform configuration with prefix support
│   ├── lambda.tf                     # Lambda functions and IAM (prefix-aware)
│   ├── bedrock_agent.tf              # Bedrock agent configuration (prefix-aware)
│   ├── bedrock_knowledge_base_simple.tf # Knowledge base with OpenSearch Serverless
│   ├── api_gateway.tf                # API Gateway REST API configuration
│   ├── cognito.tf                    # Cognito User Pool for authentication
│   ├── outputs.tf                    # Terraform outputs (prefix-aware)
│   ├── terraform.tfvars              # 🔧 Your personal config (git-ignored, prefix settings)
│   ├── terraform.tfvars.example      # 📋 Example configuration file
│   ├── terraform.tfstate             # ⚠️ CRITICAL: Infrastructure state (DO NOT DELETE)
│   │                                 # 💡 Use remote state for production (S3 + DynamoDB)
│   └── .terraform/                   # Terraform working directory
├── scripts/                          # 🛠️ Deployment and Management Scripts
│   ├── deploy-complete.sh            # 🚀 Complete automated deployment with auto-config
│   ├── deploy-lambda.sh              # Deploy Lambda functions (prefix-aware)
│   ├── deploy-direct.sh              # Deploy direct model Lambda only
│   ├── deploy-agent.sh               # Deploy agent Lambda only
│   ├── build.sh                      # Build Lambda packages
│   ├── test-lambda.sh                # 🧪 Testing script (prefix-aware)
│   ├── dev-workflow.sh               # 🛠️ Development helper (prefix-aware)
│   ├── teardown-complete.sh          # 🔥 Complete infrastructure teardown with S3 cleanup
│   ├── teardown-infrastructure.sh    # 🏗️ Infrastructure-only teardown
│   ├── teardown-s3-only.sh           # 🪣 S3 data teardown
│   ├── import-existing-resources.sh  # 🆘 State recovery script (prefix-aware)
│   ├── setup-knowledge-base-s3.sh    # 📦 Legacy S3 setup (external buckets)
│   ├── get-cognito-config.sh         # 🔐 Get Cognito configuration
│   └── check-knowledge-base-s3.sh    # 🔍 Check S3 status
├── src/                              # 💻 Lambda Source Code
│   ├── lambda_direct/
│   │   └── index.py                  # Direct model access Lambda
│   └── lambda_agent/
│       └── index.py                  # Agent-based Lambda
├── frontend/                         # ⚛️ React Frontend Application
│   ├── public/
│   │   └── index.html                # HTML template
│   ├── src/
│   │   ├── components/               # React components
│   │   │   ├── Header.js             # App header with user info
│   │   │   ├── TabBar.js             # Navigation tabs
│   │   │   ├── CityInput.js          # City input with autocomplete
│   │   │   ├── ResponseCard.js       # Response display component
│   │   │   ├── ResponseComparison.js # AI comparison component
│   │   │   ├── HistorySidebar.js     # Query history sidebar
│   │   │   └── LambdaTab.js          # Main tab with API calls
│   │   ├── App.js                    # Main App component with tabs
│   │   ├── App.css                   # App styles
│   │   ├── aws-config.js             # AWS Amplify/Cognito config (auto-updated)
│   │   ├── index.js                  # React entry point
│   │   └── index.css                 # Global styles
│   ├── package.json                  # Dependencies and scripts
│   └── README.md                     # Frontend documentation
├── data/                             # 📊 Test Data and Knowledge Base Content
│   ├── lambda-tests/                 # Test payloads
│   │   ├── direct-*.json             # Direct Lambda test payloads
│   │   ├── agent-*.json              # Agent Lambda test payloads
│   │   └── README.md
│   └── knowledge-base/               # Knowledge base source data
│       ├── world_cities_air_quality_water_pollution_2021.csv
│       ├── world_cities_cost_of_living_2018.csv
│       ├── world-cities-overview.md
│       └── README.md
├── docs/                             # 📖 Documentation
│   ├── API.md                        # Complete API documentation with OpenAPI specs
│   ├── AUTHENTICATION.md             # Cognito authentication guide
│   ├── DEPLOYMENT.md                 # Deployment instructions
│   ├── DEVELOPER_GUIDE.md            # This file
│   ├── FRONTEND_DEPLOYMENT.md        # Frontend deployment guide
│   ├── TALK_POINTS.md                # Presentation talking points
│   ├── bedrock-full-comparison.png   # Architecture comparison diagram
│   ├── full-stack-architecture.png   # Full stack architecture diagram
│   └── frontend-ui-example.png       # Frontend UI screenshot
├── generated-diagrams/               # 🎨 Generated architecture diagrams
│   └── full-stack-architecture.png
├── .gitignore                        # Git ignore patterns
├── .gitattributes                    # Git attributes
├── CONTRIBUTING.md                   # Contribution guidelines
├── LICENSE                           # MIT License
├── *.zip                             # Generated Lambda packages (git-ignored)
├── test_*.json                       # Generated test results (git-ignored)
└── README.md                         # Main project documentation
```

### 🚀 Quick Start Commands

```bash
# Complete deployment (from project root)
./scripts/deploy-complete.sh dts

# Update Lambda code only
./scripts/deploy-lambda.sh

# Test functions
./scripts/test-lambda.sh both Geneva

# Development workflow helper
./scripts/dev-workflow.sh status

# Terraform operations
cd terraform && terraform plan && cd ..

# Complete teardown
./scripts/teardown-complete.sh
```

## 📊 Current Components

### Lambda Functions
- **Direct**: `bedrock-agent-testbed-city-facts-direct` - Direct Claude 3 Haiku access
- **Agent**: `bedrock-agent-testbed-city-facts-agent` - Bedrock agent integration

### Bedrock Agent
- **Agent ID**: Retrieved from Terraform output
- **Model**: Claude 3 Haiku (`anthropic.claude-3-haiku-20240307-v1:0`)
- **Action Groups**: CityFactsActionGroup (invokes direct Lambda)
- **Knowledge Base**: Integrated with OpenSearch Serverless

### Knowledge Base
- **Vector Store**: OpenSearch Serverless
- **Embedding Model**: Amazon Titan Text Embeddings
- **Data Sources**: 
  - World cities air quality and water pollution (2021)
  - World cities cost of living (2018)

## 📊 Knowledge Base Data Sources

This project uses real-world datasets sourced from **[Kaggle](https://www.kaggle.com)** to demonstrate knowledge base functionality:

### Air Quality & Water Pollution Dataset (2021)
- **Coverage**: 500+ cities worldwide
- **Metrics**: Air Quality Index, Water Pollution Index
- **Format**: CSV with city, region, country, and pollution metrics
- **Use Case**: Environmental data for city comparisons

### Cost of Living Dataset (2018)
- **Coverage**: 400+ cities worldwide
- **Metrics**: Cost of Living Index, Rent Index, Groceries Index, Restaurant Price Index
- **Format**: CSV with comprehensive economic indicators
- **Use Case**: Economic data for lifestyle and affordability insights

### Data Processing
- **Purpose**: Educational and demonstration use in this Bedrock Agent test environment
- **Processing**: Data is chunked and vectorized using Amazon Titan embeddings for semantic search
- **Integration**: Accessible via Bedrock Agent through OpenSearch Serverless vector database

## 🛠️ Development Workflow

### 🚀 Simplified Workflow with Terraform-Managed S3

This approach eliminates most manual steps:

```bash
# Complete deployment (includes S3, files, and knowledge base)
./scripts/deploy-complete.sh dts

# Update Lambda code only (auto-detects prefix)
./scripts/deploy-lambda.sh

# Test functions (auto-detects prefix)  
./test-lambda.sh both Geneva

# Check deployment status (shows all resources with prefix)
./scripts/dev-workflow.sh status

# View logs (auto-detects function names)
./scripts/dev-workflow.sh logs-direct
./scripts/dev-workflow.sh logs-agent
```

### 🔄 Quick Lambda Updates (No Terraform)

For rapid development iterations:
```bash
# Deploy both functions (auto-detects prefix from terraform.tfvars)
./deploy-lambda.sh

# Deploy specific function
./deploy-direct.sh      # Direct model access only
./deploy-agent.sh       # Agent-based only
```

### 📊 Development Helper Commands

```bash
# Show comprehensive status (all resources with your prefix)
./scripts/dev-workflow.sh status

# Test with recommended cities
./scripts/dev-workflow.sh test Geneva
./scripts/dev-workflow.sh test-agent Berlin

# View recent logs
./scripts/dev-workflow.sh logs-direct
./scripts/dev-workflow.sh logs-agent

# Quick Terraform operations
./scripts/dev-workflow.sh terraform
```

### 🗂️ S3 Management (Existing Buckets)

For deployments using existing S3 buckets:
```bash
# Setup S3 bucket and upload data
./scripts/dev-workflow.sh setup-kb-s3

# Check knowledge base status
./scripts/dev-workflow.sh check-kb-s3

# Clean up (if needed)
./scripts/dev-workflow.sh cleanup-kb-s3
```

### Infrastructure Changes
```bash
# For infrastructure changes
terraform plan
terraform apply
```

## 📈 Example Responses

### Agent Response with Knowledge Base Data
```json
{
  "city": "New York City",
  "agent_response": "According to the search results, the air quality index for New York City is 46.82 and the water pollution index is 49.50. The city is known for its diverse economy, iconic landmarks like the Statue of Liberty and Central Park, and serves as a major financial center...",
  "message": "City facts for New York City generated via Bedrock Agent",
  "agent_id": "1DSXPQRXQJ",
  "session_id": "unique-session-id",
  "requested_city": "New York City",
  "source": "bedrock_agent"
}
```

## 🔧 Troubleshooting

### Common Issues

#### 1. OpenSearch Vector Index Creation (New Deployment Process)
**Problem**: Knowledge base creation fails with "no such index [bedrock-knowledge-base-default-index]"
**Solution**: The deployment process now handles this automatically, but if you encounter issues:

```bash
# Get collection ID from Terraform output
COLLECTION_ID=$(terraform output -raw opensearch_collection_id)

# Create the vector index manually
aws opensearchserverless create-index \
  --id "$COLLECTION_ID" \
  --index-name "bedrock-knowledge-base-default-index" \
  --index-schema '{
    "settings": {"index": {"knn": true}},
    "mappings": {
      "properties": {
        "embeddings": {
          "type": "knn_vector",
          "dimension": 1536,
          "method": {"name": "hnsw", "space_type": "l2", "engine": "faiss"}
        },
        "text": {"type": "text"},
        "bedrock-metadata": {"type": "text"}
      }
    }
  }' \
  --region us-east-1
```

**Root Cause**: OpenSearch Serverless requires the vector index to exist before knowledge base creation
**Prevention**: Use the complete deployment script which handles this automatically

#### 2. S3 Bucket Not Empty During Teardown
**Problem**: `terraform destroy` fails with "BucketNotEmpty" error
**Solution**: This is now handled automatically by the teardown script, but if you encounter it:

```bash
# The teardown script now automatically empties buckets, but manual cleanup:
BUCKET_NAME=$(terraform output -raw s3_knowledge_base_bucket)
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-objects --bucket $BUCKET_NAME \
  --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME \
  --query '{Objects: Versions[].{Key: Key, VersionId: VersionId}}' --output json)"
```

**Root Cause**: S3 buckets with versioning enabled require all versions to be deleted
**Prevention**: Use `./scripts/teardown-complete.sh` which handles this automatically

#### 3. OpenSearch Access Denied
**Problem**: "Access denied to create index" or "403 Forbidden" when accessing OpenSearch
**Solution**: Check your OpenSearch access configuration:

```bash
# Verify your current AWS identity
aws sts get-caller-identity

# Check if include_current_user_in_opensearch_access is enabled
grep include_current_user_in_opensearch_access terraform/terraform.tfvars

# If not set, add it to terraform.tfvars:
echo "include_current_user_in_opensearch_access = true" >> terraform/terraform.tfvars
terraform apply
```

**Root Cause**: OpenSearch access policy doesn't include your current user
**Prevention**: The default configuration now includes current user automatically

#### 4. Lambda Environment Variables Missing
**Problem**: Agent Lambda function fails with "BEDROCK_AGENT_ID environment variable not set"
**Solution**: This is now handled automatically, but if you encounter it:

```bash
# Check if Lambda has environment variables
aws lambda get-function-configuration \
  --function-name $(terraform output -raw lambda_function_agent_name) \
  --query 'Environment.Variables'

# If missing, redeploy the Lambda function
./scripts/deploy-lambda.sh
```

**Root Cause**: Lambda function missing dynamic environment variables
**Prevention**: Use the latest deployment scripts which set environment variables automatically

#### 5. Lost Terraform State File
**Problem**: Accidentally deleted `terraform.tfstate` file

**Solution**: Use the provided import script to recover state from existing AWS resources
```bash
./scripts/import-existing-resources.sh
```
This script will:
- Detect your existing S3 bucket
- Import all deployed resources back into Terraform state
- Recreate `terraform.tfvars` and `.kb-bucket-name` files
- Verify the import with `terraform plan`

**💡 Prevention**: For production environments, use [Terraform remote state](https://developer.hashicorp.com/terraform/language/state/remote) with an S3 backend and DynamoDB locking to prevent state file loss and enable team collaboration.

#### 6. Missing terraform.tfvars File
**Problem**: `terraform plan` fails with "no file exists at .kb-bucket-name"
**Solution**: 
```bash
# Option 1: Run the S3 setup script (creates terraform.tfvars automatically)
./scripts/setup-knowledge-base-s3.sh

# Option 2: Create terraform.tfvars manually with your existing bucket name
echo 'knowledge_base_bucket_name = "your-bucket-name"' > terraform/terraform.tfvars
```

#### 7. OpenSearch Index Creation Fails (Legacy)
**Problem**: "Access denied to create index" in AWS Console
**Solution**: The manual CLI approach is required due to OpenSearch Serverless permissions

#### 8. Knowledge Base Creation Fails (Legacy)
**Problem**: "no such index [bedrock-knowledge-base-default-index]"
**Solution**: Ensure Step 4 (manual index creation) is completed before running terraform apply

#### 9. Agent Access Denied to Knowledge Base
**Problem**: "Access denied when calling Bedrock KnowledgeBase retrieve"
**Solution**: Ensure the agent IAM role has `bedrock:Retrieve` permission (included in Terraform)

#### 10. Ingestion Jobs Fail
**Problem**: Ingestion jobs fail or show 0 documents processed
**Solution**: 
- Verify S3 bucket permissions
- Check CSV file format and location
- Ensure knowledge base role has S3 access

#### 11. Stuck Resources During Teardown
**Problem**: `terraform destroy` fails with resource dependencies or timeouts
**Solution**:
```bash
# Try destroying specific resource types first
terraform destroy -target=aws_bedrockagent_agent_knowledge_base_association.city_facts_kb_association_simple
terraform destroy -target=aws_bedrockagent_data_source.air_quality_data_simple
terraform destroy -target=aws_bedrockagent_data_source.cost_of_living_data_simple

# Then destroy the rest
terraform destroy
```

#### 12. OpenSearch Collection Won't Delete
**Problem**: OpenSearch Serverless collection deletion hangs or fails
**Solution**: 
- Wait 10-15 minutes (OpenSearch deletions are slow)
- Check AWS console for collection status
- Manually delete from console if Terraform fails

### Verification Commands
```bash
# Check OpenSearch collection status
aws opensearchserverless list-collections --region us-east-1

# Check knowledge base status
aws bedrock-agent list-knowledge-bases --region us-east-1

# Check ingestion job status
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id YOUR_KB_ID \
  --data-source-id YOUR_DS_ID \
  --region us-east-1
```

## 🚀 Quick Reference

### 🎯 New Deployment (Terraform-Managed S3)
```bash
# 🏗️ Deploy everything with prefix
./deploy-complete.sh dts

# 🧪 Test functions (auto-detects prefix)
./test-lambda.sh both Geneva

# 🔄 Update Lambda code only
./deploy-lambda.sh

# 📊 Check infrastructure status
./scripts/dev-workflow.sh status

# 🔥 Complete teardown
./scripts/teardown-complete.sh
```

### 🛠️ Development Operations
```bash
# 🔧 Build Lambda packages
./build.sh

# 🚀 Deploy functions (auto-detects prefix)
./deploy-lambda.sh
./deploy-direct.sh
./deploy-agent.sh

# 🧪 Test with recommended cities
./scripts/test-lambda.sh both Geneva
./scripts/dev-workflow.sh test Berlin

# 📋 View logs (auto-detects function names)
./scripts/dev-workflow.sh logs-direct
./scripts/dev-workflow.sh logs-agent

# 📊 Infrastructure operations
cd terraform && terraform plan && cd ..
cd terraform && terraform apply && cd ..
./scripts/dev-workflow.sh terraform
```

### 🗂️ Legacy Operations (External S3)
```bash
# 📦 Setup external S3 bucket
./scripts/setup-knowledge-base-s3.sh dts

# 🔍 Check S3 status
./scripts/check-knowledge-base-s3.sh

# 🧹 S3 cleanup only
./scripts/teardown-s3-only.sh
```

### 🔥 Teardown Options
```bash
# Scenario 1: Done with project permanently
./scripts/teardown-complete.sh

# Scenario 2: Pause project, keep data
./scripts/teardown-infrastructure.sh

# Scenario 3: Clean data, keep infrastructure  
./scripts/teardown-s3-only.sh

# Scenario 4: Emergency cleanup
terraform destroy
aws s3 rm s3://bucket-name --recursive
aws s3 rb s3://bucket-name
```

### 📁 File Management
```bash
# Important files to backup
terraform.tfstate      # Infrastructure state
terraform.tfvars       # Configuration variables
.kb-bucket-name        # S3 bucket reference

# Generated files (safe to delete)
*.zip                  # Lambda packages
test_*.json           # Test responses
.terraform/           # Terraform cache
```

## 🤝 Contributing

We welcome contributions to improve this project! Whether you're fixing bugs, adding features, improving documentation, or suggesting enhancements, your help is appreciated.

For detailed contribution guidelines, code of conduct, and development setup instructions, please see:

**[Contributing Guidelines](../README.md#-contributing)**
