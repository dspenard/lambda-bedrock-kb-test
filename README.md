# Bedrock Agent Test Bed with Knowledge Base

A simple, focused test environment for AWS Bedrock that demonstrates how to use Terraform to create a Bedrock agent with a small Knowledge Base to supplement the model with information available about a given city.  Users provide a city name, and Bedrock returns 10 interesting facts by combining:
- **General knowledge** from Claude 3.5 Haiku foundation model
- **Real-world data** from a knowledge base (air quality, water pollution, cost of living, and others)
- **Action groups** that invoke Lambda functions for additional processing

This project showcases two approaches: direct model access and agent-based architecture with knowledge base integration using OpenSearch Serverless vector storage.

**Testing**: This is a backend-focused project. Testing is currently done by directly invoking Lambda functions via AWS CLI. No front-end interface exists at this time.

![Bedrock Architecture Comparison](./docs/bedrock-full-comparison.png)

## 🎯 What This Demonstrates

**Input**: City name (e.g., "Geneva", "Tokyo", "Berlin")

**Output**: 10 key facts about the city including:
- Historical significance and founding
- Cultural landmarks and traditions
- Environmental data (air quality, water pollution) from knowledge base
- Economic information (cost of living) from knowledge base
- Population, geography, and interesting trivia

**Key AWS Services**:
- AWS Bedrock (Claude 3.5 Haiku model)
- Bedrock Agents with Action Groups
- Bedrock Knowledge Base with vector search
- OpenSearch Serverless for vector storage
- Lambda functions for custom logic
- S3 for knowledge base data storage

### 💡 Vector Storage Note

This project uses **OpenSearch Serverless** for vector storage because it's simple to set up and fully managed. However, it can be **expensive**:
- **Dev/Test** (1 OCU, no redundancy): ~$175/month
- **Production** (2 OCUs with redundancy): ~$350/month minimum
- **Production** (4 OCUs with redundancy): ~$700/month

**For Bedrock RAG systems, consider these Bedrock-supported alternatives:**

**AWS Native Options:**
- **Amazon Aurora PostgreSQL with pgvector** - Cost-effective, familiar SQL interface, fully supported
- **Amazon Neptune Analytics** - Graph database with vector search capabilities

**Third-Party Options (Bedrock-Supported):**
- **Pinecone** - Purpose-built vector database, pay-per-use pricing
- **MongoDB Atlas** - Document database with vector search
- **Redis Enterprise** - In-memory database with vector capabilities

---

## 🚀 Quick Start

If you're up to speed on Git, Terraform, and AWS CLI and setting its credentials, then follow these steps for a complete deployment in ~10 minutes.

**[📄 Quick Start Guide →](docs/DEPLOYMENT.md)**

The Quick Start guide includes:
- Prerequisites checklist
- One-command deployment
- Testing instructions
- Teardown commands

---

## 📚 Table of Contents

- [Architecture Overview](#️-architecture-overview)
- [Deployment and Teardown](#-deployment-and-teardown)
- [Testing](#-testing)
- [API Documentation](#-api-documentation)
- [Development Workflow](#️-development-workflow)
- [Project Structure](#-project-structure)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Architecture Overview

This project demonstrates **two distinct approaches** to using AWS Bedrock for generating city information:

### Approach 1: Direct Model Access (Simple)
```
┌─────────────────┐
│   User Input    │
│ {"city":"Tokyo"}│
└─────────┬───────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Lambda Direct (lambda_direct)                   │
│  • Receives city name                                   │
│  • Constructs prompt                                    │
│  • Calls bedrock-runtime.invoke_model()                 │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Claude 3.5 Haiku Foundation Model               │
│  • Processes prompt                                     │
│  • Generates 10 city facts using large language model   │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────┐
│   Response      │
│ • 10 facts      │
│ • General info  │
└─────────────────┘
```

### Approach 2: Agent-Based with Knowledge Base (Advanced)
```
┌─────────────────┐
│   User Input    │
│{"city":"Geneva"}│
└─────────┬───────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Lambda Agent (lambda_agent)                     │
│  • Receives city name                                   │
│  • Constructs detailed prompt                           │
│  • Calls bedrock-agent-runtime.invoke_agent()           │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Bedrock Agent (Claude 3.5 Haiku)                │
│  • Orchestrates multiple data sources                   │
│  • Plans response strategy                              │
│  • Decides which tools to use based on prompt           │
└─────────┬───────────────────┬───────────────────────────┘
          │                   │
          │                   ▼
          │        ┌──────────────────────────────────┐
          │        │     Knowledge Base               │
          │        │  (OpenSearch Serverless)         │
          │        │                                  │
          │        │ • Vector search for city data    │
          │        │ • Air quality (500+ cities)      │
          │        │ • Water pollution metrics        │
          │        │ • Cost of living (400+ cities)   │
          │        │ • Associated with agent          │
          │        └──────────┬───────────────────────┘
          │                   │
          │                   ▼
          │        ┌──────────────────┐
          │        │   S3 Bucket      │
          │        │ • CSV datasets   │
          │        │ • Vector indexed │
          │        └──────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│    Action Group: /city-facts API (Internal)             │
│  • Agent calls POST /city-facts internally              │
│  • Defined by OpenAPI spec in agent config              │
│  • Executor: lambda_direct function                     │
│  • NOT called directly by users                         │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Lambda Direct (as Action Group)                 │
│  • Invoked by agent via action group                    │
│  • Gets general city facts from model                   │
│  • Returns structured data to agent                     │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│         Agent Synthesizes Response                      │
│  • Combines knowledge base data                         │
│  • Integrates action group results                      │
│  • Generates coherent narrative                         │
└─────────┬───────────────────────────────────────────────┘
          │
          ▼
┌─────────────────┐
│   Response      │
│ • 10 facts      │
│ • KB data       │
│ • General info  │
└─────────────────┘
```

### Key Differences

| Feature | Direct Model Access | Agent-Based |
|---------|-------------------|-------------|
| **Lambda Function** | `lambda_direct` | `lambda_agent` |
| **Bedrock API** | `invoke_model()` | `invoke_agent()` |
| **Data Sources** | Large language model only | Model + Knowledge Base + Action Groups |
| **Complexity** | Simple, single API call | Orchestrated, multi-source |
| **Knowledge Base** | ❌ No | ✅ Yes (OpenSearch, associated with agent) |
| **Action Groups** | ❌ No | ✅ Yes (`/city-facts` API, internal only) |
| **Real-time Data** | ❌ No | ✅ Yes (from CSV datasets) |
| **Use Case** | Baseline testing | Full Bedrock capabilities |
| **API Invocation** | Direct Lambda call | Agent orchestrates internal APIs |

### How Each Approach Works

**Direct Model Access:**
1. User provides city name → `{"city": "Tokyo"}`
2. Lambda constructs prompt → "Provide 10 facts about Tokyo"
3. Calls Bedrock Runtime → `invoke_model()` with Claude 3.5 Haiku
4. Model generates response → Using large language model
5. Returns 10 facts → General knowledge only

**Agent-Based:**
1. User provides city name → `{"city": "Geneva"}`
2. Lambda constructs prompt → "Tell me about Geneva, including air quality, water pollution, and cost of living"
3. Calls Bedrock Agent → `invoke_agent()` 
4. Agent orchestrates (automatically decides which tools to use):
   - **Knowledge Base Search** → Agent queries OpenSearch for Geneva data (air quality, water pollution, cost of living)
     - Knowledge base is **associated with the agent** via Terraform configuration
     - Agent has IAM permissions to call `bedrock:Retrieve`
   - **Action Group Call** → Agent internally calls `POST /city-facts` API
     - This API is defined in the agent's OpenAPI specification
     - The API is **not called directly by users** - only by the agent
     - Executor is `lambda_direct` function
     - Returns general city facts from the model
5. Agent synthesizes → Combines knowledge base data + action group results
6. Returns comprehensive response → KB data + general facts

**Key Insight**: The `/city-facts` API is an **internal tool** for the agent. Users never call it directly - they call `lambda_agent`, which invokes the Bedrock Agent, which then decides to use the `/city-facts` action group as one of its tools.

## 🚀 Deployment and Teardown

For complete deployment instructions, teardown options, and step-by-step guides, see:

**[📄 Deployment and Teardown Guide](docs/DEPLOYMENT.md)**

The deployment guide includes:
- **Simplified Deployment** - One-command deployment (recommended)
- **Resource Prefixing** - Multi-developer environment support
- **Manual Deployment** - Step-by-step instructions for advanced users
- **Complete Teardown** - Remove all resources and avoid charges
- **Partial Teardown** - Infrastructure-only or S3-only cleanup options
- **Cost Information** - Detailed cost implications and redeployment instructions

## 🧪 Testing

### 🚀 Quick Testing with Scripts

The testing scripts automatically detect your resource prefix and use the correct function names:

```bash
# Test both direct and agent-based approaches with cities that have complete data
./test-lambda.sh both Geneva

# Test specific functions with knowledge base cities
./test-lambda.sh direct Berlin
./test-lambda.sh agent "Zurich"

# Use development workflow helper with recommended cities
./scripts/dev-workflow.sh test Basel
```

### 🎯 Automatic Prefix Detection

All scripts automatically detect your prefix from `terraform.tfvars`:

```bash
# If terraform.tfvars contains: resource_prefix = "dts"
./test-lambda.sh both Geneva
# → Tests: dts-bedrock-agent-testbed-city-facts-direct
# → Tests: dts-bedrock-agent-testbed-city-facts-agent

# Without prefix
./test-lambda.sh both Geneva  
# → Tests: bedrock-agent-testbed-city-facts-direct
# → Tests: bedrock-agent-testbed-city-facts-agent
```

## 📖 API Documentation

### Complete API Specification

For comprehensive API documentation including OpenAPI specifications, request/response examples, and integration patterns, see:

**[📄 docs/API.md](docs/API.md)**

The API documentation includes:
- **OpenAPI 3.0 Specification** for the City Facts Action Group API
- **Request/Response Examples** for both Lambda functions
- **Error Handling** patterns and common error codes
- **Integration Examples** in Python and Node.js
- **Usage Patterns** for different testing scenarios
- **Rate Limits and Best Practices**

### Quick API Reference

#### Lambda Direct (Simple Model Access)

**Input**:
```json
{"city": "Tokyo"}
```

**Output**:
```json
{
  "city": "Tokyo",
  "facts": ["fact 1", "fact 2", ...],
  "total_facts": 10,
  "message": "Here are facts about Tokyo generated by Claude 3 Haiku!",
  "model_used": "anthropic.claude-3-haiku-20240307-v1:0"
}
```

#### Lambda Agent (Agent-Based with Knowledge Base)

**Input**:
```json
{"city": "Geneva"}
```

**Output**:
```json
{
  "city": "Geneva",
  "agent_response": "Here is what I can share about Geneva:\n\nBased on the search results, Geneva has an air quality index of 20.17...",
  "message": "City facts for Geneva generated via Bedrock Agent",
  "agent_id": "137GJDIGTS",
  "session_id": "unique-session-id",
  "source": "bedrock_agent"
}
```

### Testing Commands

```bash
# Test direct Lambda
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Tokyo"}' \
  response.json

# Test agent Lambda
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Geneva"}' \
  response.json
```

### Manual Testing Examples

#### Test Direct Model Access
```bash
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Berlin"}' \
  response_direct.json
```

#### Test Agent with Knowledge Base
```bash
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Geneva"}' \
  response_agent.json
```

#### Test Cities with Knowledge Base Data

The knowledge base contains two datasets with extensive city coverage:

**🌟 Recommended Test Cities (Complete Data in Both Datasets):**
These cities have both air quality/water pollution AND cost of living data, providing the richest agent responses:

- **Geneva, Switzerland** - High cost of living, excellent air quality
- **Zurich, Switzerland** - Premium living costs, clean environment  
- **Basel, Switzerland** - Swiss quality with complete datasets
- **Berlin, Germany** - European capital with moderate costs
- **London, United Kingdom** - Global financial center
- **Paris, France** - Cultural capital with urban challenges
- **Boston, USA** - American tech hub with good data
- **Chicago, USA** - Major US city with comprehensive info
- **Los Angeles, USA** - West Coast metropolis
- **Montreal, Canada** - Bilingual city with full datasets

**🌍 Additional Cities with Complete Data:**
Athens, Bangkok, Barcelona, Beijing, Bern, Brussels, Buenos Aires, Delhi, Dubai, Dublin, Helsinki, Lisbon, Madrid, Milan, Miami, Moscow, Mumbai, Oslo

**📊 Dataset Coverage:**
- **Air Quality & Water Pollution**: 500+ cities worldwide (2021 data)
- **Cost of Living**: 400+ cities worldwide (2018 data)  
- **Both Datasets**: 200+ cities with complete information

**🧪 Testing Examples:**
```bash
# Cities with rich knowledge base data
./test-lambda.sh agent "Geneva"
./test-lambda.sh agent "Berlin" 
./test-lambda.sh agent "Tokyo"

# Compare different data availability
./test-lambda.sh both "Geneva"    # Complete data from both sources
./test-lambda.sh both "Singapore" # Partial data, general facts
```

**💡 Pro Tip:** Cities with data in both datasets will provide more comprehensive responses as the agent can combine air quality, water pollution, and cost of living information with general city facts.

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

The new approach eliminates most manual steps:

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

### 🗂️ Legacy S3 Management (External Buckets)

For existing deployments using external S3 buckets:
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

## 📁 Project Structure

```
.
├── terraform/                        # 🏗️ Infrastructure as Code
│   ├── main.tf                       # Main Terraform configuration with prefix support
│   ├── lambda.tf                     # Lambda functions and IAM (prefix-aware)
│   ├── bedrock_agent.tf              # Bedrock agent configuration (prefix-aware)
│   ├── bedrock_knowledge_base_simple.tf # Knowledge base with Terraform-managed S3
│   ├── outputs.tf                    # Terraform outputs (prefix-aware)
│   ├── terraform.tfvars              # 🔧 Your personal config (git-ignored, prefix settings)
│   ├── terraform.tfvars.example      # 📋 Example configuration file
│   ├── terraform.tfstate             # ⚠️ CRITICAL: Infrastructure state (DO NOT DELETE)
│   └── .terraform/                   # Terraform working directory
├── scripts/                          # 🛠️ Deployment and Management Scripts
│   ├── deploy-complete.sh            # 🚀 Complete automated deployment (NEW)
│   ├── deploy-lambda.sh              # Deploy Lambda functions (prefix-aware)
│   ├── deploy-direct.sh              # Deploy direct model Lambda only
│   ├── deploy-agent.sh               # Deploy agent Lambda only
│   ├── build.sh                      # Build Lambda packages
│   ├── test-lambda.sh                # 🧪 Testing script (prefix-aware)
│   ├── dev-workflow.sh               # 🛠️ Development helper (prefix-aware)
│   ├── teardown-complete.sh          # 🔥 Complete infrastructure teardown
│   ├── teardown-infrastructure.sh    # 🏗️ Infrastructure-only teardown
│   ├── teardown-s3-only.sh           # 🪣 S3 data teardown
│   ├── import-existing-resources.sh  # 🆘 State recovery script (prefix-aware)
│   ├── setup-knowledge-base-s3.sh    # 📦 Legacy S3 setup (external buckets)
│   └── check-knowledge-base-s3.sh    # 🔍 Check S3 status
├── src/                              # 💻 Lambda Source Code
│   ├── lambda_direct/
│   │   └── index.py                  # Direct model access Lambda
│   └── lambda_agent/
│       └── index.py                  # Agent-based Lambda
├── data/                             # 📊 Test Data and Knowledge Base Content
│   ├── lambda-tests/                 # Test payloads
│   │   ├── direct-*.json
│   │   ├── agent-*.json
│   │   └── README.md
│   └── knowledge-base/               # Knowledge base source data
│       ├── world_cities_air_quality_water_pollution_2021.csv
│       ├── world_cities_cost_of_living_2018.csv
│       └── README.md
├── docs/                             # 📖 Documentation
│   ├── API.md                        # Complete API documentation with OpenAPI specs
│   └── bedrock-full-comparison.png   # Architecture diagram
├── .kb-bucket-name                   # 📝 S3 bucket name reference (legacy)
├── *.zip                             # Generated Lambda packages (git-ignored)
├── test_*.json                       # Generated test results (git-ignored)
└── README.md                         # This file
```

### 🔑 Key Files and Folders

**📁 terraform/** - Infrastructure as Code
- All Terraform configuration files
- Your personal `terraform.tfvars` settings (optional - has defaults)
- **CRITICAL**: `terraform.tfstate` file (never delete!)

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
- `bedrock-full-comparison.png` - Architecture diagram

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

## 🎯 Features

✅ **Direct Bedrock Integration**: Lambda function with Claude 3 Haiku  
✅ **Bedrock Agent**: Complete agent with action groups  
✅ **Knowledge Base**: OpenSearch Serverless with vector embeddings  
✅ **Dual Data Sources**: Air quality and cost of living data  
✅ **Automated Ingestion**: CSV data processing and vectorization  
✅ **Comprehensive IAM**: Proper permissions for all components  
✅ **Development Tools**: Scripts for rapid deployment and testing  
✅ **Error Handling**: Graceful handling of missing data  
✅ **Internal Action Group API**: `/city-facts` API for agent orchestration (not user-facing)

### 🔑 Key Architectural Concepts

**Knowledge Base Association**: The knowledge base is associated with the Bedrock Agent via Terraform, giving the agent automatic access to search it. The `lambda_direct` function does not have direct knowledge base access - only the agent does.

**Action Group API**: The `/city-facts` API is an internal tool defined in the agent's OpenAPI specification. Users never call it directly - only the Bedrock Agent calls it as part of its orchestration process.

**Two Invocation Paths**:
- **Direct**: User → `lambda_direct` → Model → Response (no KB)
- **Agent**: User → `lambda_agent` → Agent → (KB search + `/city-facts` call) → Synthesized Response  

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔮 Next Steps

- [ ] Add front-end interface (Streamlit, React, etc) with API Gateway integration to provide a user-friendly UI for querying city facts
- [ ] Implement Bedrock Guardrails to filter inappropriate content and enforce safety policies
- [ ] Explore multi-agent architecture where specialized agents handle different aspects (e.g., one for environmental data, one for cultural facts, etc)
- [ ] Add more data sources to knowledge base
- [ ] Implement conversation memory
- [ ] Create additional action groups
- [ ] Add monitoring and alerting
- [ ] Implement automated testing pipeline

## 📝 Notes

- **Region**: All resources deployed in `us-east-1`
- **Model**: Claude 3 Haiku for cost-effective testing
- **Vector Store**: OpenSearch Serverless for managed vector search
- **Embeddings**: Amazon Titan Text Embeddings (1536 dimensions)
- **Manual Step**: OpenSearch index creation required due to permissions

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

### File Management
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