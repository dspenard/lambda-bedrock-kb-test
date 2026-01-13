# Bedrock Agent Test Bed with Knowledge Base

A comprehensive test environment for AWS Lambda functions integrated with Bedrock agents and knowledge bases, featuring both direct model access and agent-based architectures with OpenSearch Serverless vector storage.

> **⚠️ IMPORTANT: Terraform State Management**
> 
> This project uses Terraform to manage AWS infrastructure. The `terraform.tfstate` file is **CRITICAL** - it maps your configuration to actual AWS resources. 
> 
> - **Never delete** `terraform.tfstate` 
> - **Back it up** regularly
> - **Don't commit it** to version control (contains sensitive data)
> - If lost, use `./import-existing-resources.sh` to recover

## 🏗️ Architecture Overview

### Complete System Architecture
```
┌─────────────────┐
│   User Request  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Lambda (Agent)  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌──────────────────┐
│ Bedrock Agent   │◄──►│ Knowledge Base   │
│ (Claude 3 Haiku)│    │ (OpenSearch)     │
└─────────┬───────┘    └──────────────────┘
          │                      ▲
          ▼                      │
┌─────────────────┐    ┌──────────────────┐
│  Action Group   │    │   S3 Data        │
└─────────┬───────┘    │ • Air Quality    │
          │            │ • Cost of Living │
          ▼            └──────────────────┘
┌─────────────────┐
│ Lambda (Direct) │
│ Claude 3 Haiku  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│    Response     │
└─────────────────┘
```

## 🔐 AWS Access and Permissions Requirements

### AWS CLI Configuration

Before deploying this infrastructure, ensure you have AWS CLI configured with appropriate credentials:

#### Option 1: Default Profile
```bash
# Configure AWS CLI with default profile
aws configure

# Verify your configuration
aws sts get-caller-identity
```

#### Option 2: Named Profile (Recommended)
Using named profiles allows you to manage multiple AWS accounts and switch between them easily:

```bash
# Configure AWS CLI with a named profile
aws configure --profile my-profile

# Set the profile for your current session
export AWS_PROFILE=my-profile

# Verify your configuration
aws sts get-caller-identity
```

#### Alternative Authentication Methods

For different environments, consider these alternatives:
- **AWS SSO**: `aws sso configure`
- **IAM Roles**: Use EC2 instance profiles or assume roles
- **AWS Vault**: Third-party tool for secure credential management

### Required AWS Permissions

This project requires extensive AWS permissions to create and manage multiple services. The following permissions are needed:

#### Core Infrastructure Permissions
- **IAM**: Create and manage roles, policies, and policy attachments
- **Lambda**: Create, update, and invoke functions
- **CloudWatch**: Create and manage log groups
- **S3**: Create buckets, upload objects, and manage bucket policies

#### Bedrock Permissions
- **Bedrock**: Access to foundation models, create agents, knowledge bases, and data sources
- **Bedrock Agent**: Create and manage agents, action groups, and knowledge base associations
- **Bedrock Runtime**: Invoke models and retrieve from knowledge bases

#### OpenSearch Serverless Permissions
- **OpenSearch Serverless**: Create collections, security policies, and access policies
- **OpenSearch**: Create and manage vector indices

#### Minimum IAM Policy

For production environments, you can use this minimal policy instead of admin access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PassRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:InvokeFunction",
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy",
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "bedrock:CreateAgent",
                "bedrock:DeleteAgent",
                "bedrock:GetAgent",
                "bedrock:UpdateAgent",
                "bedrock:CreateAgentActionGroup",
                "bedrock:DeleteAgentActionGroup",
                "bedrock:GetAgentActionGroup",
                "bedrock:UpdateAgentActionGroup",
                "bedrock:CreateKnowledgeBase",
                "bedrock:DeleteKnowledgeBase",
                "bedrock:GetKnowledgeBase",
                "bedrock:UpdateKnowledgeBase",
                "bedrock:CreateDataSource",
                "bedrock:DeleteDataSource",
                "bedrock:GetDataSource",
                "bedrock:UpdateDataSource",
                "bedrock:StartIngestionJob",
                "bedrock:GetIngestionJob",
                "bedrock:ListIngestionJobs",
                "bedrock:AssociateAgentKnowledgeBase",
                "bedrock:DisassociateAgentKnowledgeBase",
                "bedrock:InvokeModel",
                "bedrock:Retrieve",
                "aoss:CreateCollection",
                "aoss:DeleteCollection",
                "aoss:UpdateCollection",
                "aoss:BatchGetCollection",
                "aoss:ListCollections",
                "aoss:CreateSecurityPolicy",
                "aoss:DeleteSecurityPolicy",
                "aoss:GetSecurityPolicy",
                "aoss:UpdateSecurityPolicy",
                "aoss:ListSecurityPolicies",
                "aoss:CreateAccessPolicy",
                "aoss:DeleteAccessPolicy",
                "aoss:GetAccessPolicy",
                "aoss:UpdateAccessPolicy",
                "aoss:ListAccessPolicies",
                "aoss:APIAccessAll"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Simplified Approach: Use Admin Access

For development and testing, the easiest approach is to use an IAM user or role with `AdministratorAccess` policy:

```bash
# Check if you have admin access
aws iam get-user
aws sts get-caller-identity

# Your user should have the AdministratorAccess policy attached
```

### AWS Region Requirements

This project is configured for **us-east-1** region. Ensure your AWS CLI is configured for this region:

```bash
# Check current region
aws configure get region

# Set region if needed
aws configure set region us-east-1
```

### Bedrock Model Access

Ensure you have access to the required Bedrock models in us-east-1:

1. **Go to AWS Console → Bedrock → Model Access**
2. **Request access** to the following models, if required:
   - `Claude 3 Haiku` (anthropic.claude-3-haiku-20240307-v1:0)
   - `Amazon Titan Text Embeddings` (amazon.titan-embed-text-v1)

3. **Verify access** via CLI:
```bash
# List available models
aws bedrock list-foundation-models --region us-east-1

# Check specific model access
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-haiku-20240307-v1:0 \
  --region us-east-1
```

### Testing Your Access

Before proceeding with deployment, test your permissions:

```bash
# Test basic AWS access
aws sts get-caller-identity

# Test S3 access
aws s3 ls

# Test Lambda access
aws lambda list-functions --region us-east-1

# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1

# Test OpenSearch Serverless access
aws opensearchserverless list-collections --region us-east-1
```

## 🚀 Quick Start Deployment

### Option 1: Automated Deployment (Recommended)

For a completely automated deployment, use the provided script:

```bash
# Clone and navigate to the project
git clone https://github.com/your-username/bedrock-agent-testbed.git
cd bedrock-agent-testbed

# Run the complete deployment script
./deploy-complete.sh
```

This script will:
1. Initialize Terraform
2. Deploy core infrastructure
3. Setup S3 bucket and upload data
4. Create OpenSearch collection
5. Create the vector index automatically
6. Deploy the knowledge base
7. Ingest all data sources
8. Test the deployment

### Option 2: Manual Step-by-Step Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed
- `jq` for JSON processing (optional, for testing)

### ⚠️ Important: Terraform State Management

**CRITICAL**: The `terraform.tfstate` file contains the mapping between your Terraform configuration and your actual AWS resources. **Never delete or lose this file!**

- ✅ **Keep it safe**: Back up your `terraform.tfstate` file regularly
- ✅ **Don't commit it**: The `.gitignore` file excludes it from version control (contains sensitive data)
- ✅ **Team usage**: For team environments, consider using [Terraform remote state](https://developer.hashicorp.com/terraform/language/settings/backends)
- ❌ **Never delete**: If lost, you'll need to manually import all resources (see `import-existing-resources.sh`)

### Configuration Files

This project uses several configuration files:

1. **`terraform.tfvars`** - Contains your S3 bucket name (created by `setup-knowledge-base-s3.sh`)
   ```hcl
   knowledge_base_bucket_name = "bedrock-kb-xxxxxxxx"
   ```

2. **`.kb-bucket-name`** - Backup reference file with S3 bucket name

3. **`terraform.tfstate`** - **CRITICAL** - Contains your infrastructure state mapping

**Note**: The knowledge base components are conditional - they only deploy when `knowledge_base_bucket_name` is provided in `terraform.tfvars`.

### Step 1: Initial Infrastructure Setup
```bash
# Clone and navigate to the project
git clone https://github.com/your-username/bedrock-agent-testbed.git
cd bedrock-agent-testbed

# Initialize Terraform
terraform init

# Deploy core infrastructure (Lambda functions, IAM roles, Bedrock agent)
terraform apply
```

### Step 2: Knowledge Base S3 Setup
```bash
# Create S3 bucket and upload knowledge base data
./setup-knowledge-base-s3.sh

# This script will:
# - Create a uniquely named S3 bucket (bedrock-kb-xxxxxxxx)
# - Upload both CSV files to the bucket
# - Create terraform.tfvars with the bucket name
# - Create .kb-bucket-name as a backup reference

# Verify upload
./check-knowledge-base-s3.sh
```

### Step 3: Deploy Knowledge Base Infrastructure
```bash
# Deploy OpenSearch Serverless collection and knowledge base
terraform apply
```

### Step 4: **AUTOMATED** - Create OpenSearch Vector Index

Use the provided script to automate the manual step:

```bash
# Create the vector index automatically
./create-opensearch-index.sh
```

**OR** create it manually:

1. **Get the collection ID** from Terraform output or run:
   ```bash
   aws opensearchserverless list-collections --region us-east-1
   ```

2. **Create the vector index** using AWS CLI:
   ```bash
   # Replace COLLECTION_ID with your actual collection ID
   aws opensearchserverless create-index \
     --id COLLECTION_ID \
     --index-name bedrock-knowledge-base-default-index \
     --index-schema '{
       "settings": {
         "index": {
           "knn": true
         }
       },
       "mappings": {
         "properties": {
           "embeddings": {
             "type": "knn_vector",
             "dimension": 1536,
             "method": {
               "name": "hnsw",
               "space_type": "l2",
               "engine": "faiss"
             }
           },
           "text": {
             "type": "text"
           },
           "bedrock-metadata": {
             "type": "text"
           }
         }
       }
     }' \
     --region us-east-1
   ```

3. **Verify index creation**:
   ```bash
   aws opensearchserverless get-index \
     --id COLLECTION_ID \
     --index-name bedrock-knowledge-base-default-index \
     --region us-east-1
   ```

### Step 5: Complete Knowledge Base Setup
```bash
# Deploy the knowledge base (now that the index exists)
terraform apply

# The knowledge base should now be created successfully
```

### Step 6: Ingest Knowledge Base Data
```bash
# Get knowledge base and data source IDs from Terraform output
KB_ID=$(terraform output -raw knowledge_base_id)
DS1_ID=$(terraform output -raw air_quality_data_source_id)
DS2_ID=$(terraform output -raw cost_of_living_data_source_id)

# Start ingestion for air quality data
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS1_ID \
  --description "Initial ingestion of air quality data" \
  --region us-east-1

# Wait for completion, then start cost of living data ingestion
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS2_ID \
  --description "Initial ingestion of cost of living data" \
  --region us-east-1
```

### Step 7: Test the Complete System
```bash
# Test the agent with knowledge base integration
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "New York City"}' \
  response.json

# View the response
cat response.json | jq -r '.body' | jq .
```

## 🧪 Testing

### Quick Testing with Scripts
```bash
# Test both direct and agent-based approaches with cities that have complete data
./test-lambda.sh both Geneva

# Test specific functions with knowledge base cities
./test-lambda.sh direct Berlin
./test-lambda.sh agent "Zurich"

# Use development workflow helper with recommended cities
./dev-workflow.sh test Basel
```

## 🔥 Teardown and Cleanup

This project provides multiple teardown options depending on your needs. Choose the appropriate method based on your situation:

### 🎯 Teardown Decision Guide

**Use Complete Teardown when:**
- You're done with the project permanently
- You want to avoid all AWS charges
- You need to clean up everything for a fresh start

**Use Infrastructure-Only Teardown when:**
- You want to pause the project temporarily
- You want to keep your knowledge base data
- You plan to redeploy soon

**Use S3-Only Teardown when:**
- You want to clean up data but keep infrastructure
- You're testing with different datasets
- You want to reduce storage costs only

---

### 1. Complete Teardown (Recommended for final cleanup)

**Command:**
```bash
./teardown-complete.sh
```

**Interactive Process:**
1. **Confirmation**: Script shows all resources to be destroyed
2. **Infrastructure**: Destroys all Terraform-managed resources
3. **S3 Cleanup**: Asks if you want to delete S3 bucket and data
4. **Local Files**: Asks if you want to clean up configuration files

**What gets destroyed:**
- ✅ All Lambda functions and IAM roles
- ✅ Bedrock agent and action groups
- ✅ Knowledge base and data sources
- ✅ OpenSearch Serverless collection
- ✅ CloudWatch log groups
- ✅ S3 bucket and data (optional)
- ✅ Local configuration files (optional)

**Estimated time:** 5-10 minutes (OpenSearch deletion is slow)

**Cost impact:** Eliminates all ongoing charges

---

### 2. Infrastructure-Only Teardown

**Command:**
```bash
./teardown-infrastructure.sh
```

**Process:**
1. **Verification**: Checks for terraform.tfstate file
2. **Resource List**: Shows all resources to be destroyed
3. **Confirmation**: Single confirmation prompt
4. **Destruction**: Runs `terraform destroy`

**What gets destroyed:**
- ✅ All Terraform-managed infrastructure
- ❌ S3 bucket and data (preserved)
- ❌ Local configuration files (preserved)

**What's preserved:**
- 📦 S3 bucket with knowledge base data
- 📄 `terraform.tfvars` file
- 📄 `.kb-bucket-name` reference
- 📄 `terraform.tfstate` for reference

**Quick redeploy:** `terraform apply`

**Estimated time:** 5-10 minutes

**Cost impact:** Eliminates compute charges, keeps storage charges

---

### 3. S3-Only Teardown

**Command:**
```bash
./teardown-s3-only.sh
```

**Process:**
1. **Bucket Detection**: Finds S3 bucket from config files
2. **Content Preview**: Shows current bucket contents
3. **Confirmation**: Requires typing 'yes' to confirm
4. **Data Deletion**: Removes all objects from bucket
5. **Bucket Deletion**: Removes the bucket itself
6. **Local Cleanup**: Optionally updates local references

**What gets destroyed:**
- ✅ S3 bucket and all data
- ✅ Local bucket references (optional)
- ❌ All other infrastructure (preserved)

**⚠️ Warning:** Knowledge base data cannot be recovered once deleted

**Estimated time:** 1-2 minutes

**Cost impact:** Eliminates storage charges only

---

### 4. Manual Teardown (Advanced Users)

For granular control or troubleshooting:

```bash
# Step 1: Destroy infrastructure
terraform destroy

# Step 2: Clean up S3 (optional)
BUCKET_NAME=$(cat .kb-bucket-name)
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME

# Step 3: Clean up local files (optional)
rm -f terraform.tfstate* terraform.tfvars .kb-bucket-name
rm -rf .terraform/
rm -f *.zip test_*.json response*.json
```

---

### 🚨 Important Teardown Considerations

#### Before Teardown
- **Backup State**: Copy `terraform.tfstate` if you might need it later
- **Export Data**: Download any important test results or configurations
- **Check Dependencies**: Ensure no other projects depend on these resources

#### During Teardown
- **Be Patient**: OpenSearch collections take 5-15 minutes to delete
- **Monitor Progress**: Check AWS console if Terraform seems stuck
- **Handle Errors**: Some resources may need manual cleanup if dependencies exist

#### After Teardown
- **Verify Billing**: Check AWS billing console for remaining charges
- **Clean Console**: Manually verify resources are deleted in AWS console
- **Update Documentation**: Note any manual cleanup steps for future reference

#### Recovery Options
- **Lost State**: Use `./import-existing-resources.sh` if state file is accidentally deleted
- **Partial Failure**: Run teardown scripts multiple times - they're idempotent
- **Manual Cleanup**: Use AWS console for stuck resources

---

### 💰 Cost Implications

**Ongoing Charges (when deployed):**
- OpenSearch Serverless: ~$0.24/hour minimum
- Lambda: Pay per invocation (minimal)
- S3: ~$0.023/GB/month
- CloudWatch Logs: ~$0.50/GB ingested

**After Infrastructure Teardown:**
- S3 storage charges only (~$0.023/GB/month)

**After Complete Teardown:**
- No ongoing charges

---

### 🔄 Redeployment After Teardown

**After Infrastructure-Only Teardown:**
```bash
terraform apply  # Uses existing S3 bucket
```

**After Complete Teardown:**
```bash
./deploy-complete.sh  # Full redeployment needed
```

**After S3-Only Teardown:**
```bash
./setup-knowledge-base-s3.sh  # Recreate S3 bucket
terraform apply                # Update knowledge base
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

### Quick Lambda Updates (No Terraform)
```bash
# Deploy both functions
./deploy-lambda.sh

# Deploy specific function
./deploy-direct.sh      # Direct model access only
./deploy-agent.sh       # Agent-based only
```

### Knowledge Base Management
```bash
# Setup S3 bucket and upload data
./dev-workflow.sh setup-kb-s3

# Check knowledge base status
./dev-workflow.sh check-kb-s3

# Clean up (if needed)
./dev-workflow.sh cleanup-kb-s3
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
├── main.tf                           # Main Terraform configuration
├── lambda.tf                         # Lambda functions and IAM
├── bedrock_agent.tf                  # Bedrock agent configuration
├── bedrock_knowledge_base_simple.tf  # Knowledge base and data sources
├── outputs.tf                        # Terraform outputs
├── terraform.tfvars                  # 🔧 Terraform variables (created by setup script)
├── terraform.tfstate                 # ⚠️ CRITICAL: Infrastructure state (DO NOT DELETE)
├── .kb-bucket-name                   # 📝 S3 bucket name reference
├── import-existing-resources.sh      # 🆘 State recovery script
├── lambda_src/
│   └── index.py                      # Direct model access Lambda
├── lambda_agent_src/
│   └── index.py                      # Agent-based Lambda
├── data/
│   ├── lambda-tests/                 # Test payloads
│   │   ├── direct-*.json
│   │   ├── agent-*.json
│   │   └── README.md
│   └── knowledge-base/               # Knowledge base source data
│       ├── world_cities_air_quality_water_pollution_2021.csv
│       ├── world_cities_cost_of_living_2018.csv
│       └── README.md
├── build.sh                          # Build Lambda packages
├── deploy-complete.sh                # 🚀 Complete automated deployment
├── deploy-*.sh                       # Individual deployment scripts
├── teardown-complete.sh              # 🔥 Complete infrastructure teardown
├── teardown-infrastructure.sh        # 🏗️ Infrastructure-only teardown
├── teardown-s3-only.sh               # 🪣 S3 data teardown
├── create-opensearch-index.sh        # 🔧 Automate OpenSearch index creation
├── test-lambda.sh                    # Testing script
├── dev-workflow.sh                   # Development helper
├── setup-knowledge-base-s3.sh        # S3 setup for knowledge base
├── check-knowledge-base-s3.sh        # Check S3 status
├── cleanup-knowledge-base-s3.sh      # S3 cleanup (legacy)
└── README.md                         # This file
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Lost Terraform State File
**Problem**: Accidentally deleted `terraform.tfstate` file
**Solution**: Use the provided import script to recover state from existing AWS resources
```bash
./import-existing-resources.sh
```
This script will:
- Detect your existing S3 bucket
- Import all deployed resources back into Terraform state
- Recreate `terraform.tfvars` and `.kb-bucket-name` files
- Verify the import with `terraform plan`

#### 2. Missing terraform.tfvars File
**Problem**: `terraform plan` fails with "no file exists at .kb-bucket-name"
**Solution**: 
```bash
# Option 1: Run the S3 setup script (creates terraform.tfvars automatically)
./setup-knowledge-base-s3.sh

# Option 2: Create terraform.tfvars manually with your existing bucket name
echo 'knowledge_base_bucket_name = "your-bucket-name"' > terraform.tfvars
```

#### 3. OpenSearch Index Creation Fails
**Problem**: "Access denied to create index" in AWS Console
**Solution**: The manual CLI approach is required due to OpenSearch Serverless permissions

#### 4. Knowledge Base Creation Fails
**Problem**: "no such index [bedrock-knowledge-base-default-index]"
**Solution**: Ensure Step 4 (manual index creation) is completed before running terraform apply

#### 5. Agent Access Denied to Knowledge Base
**Problem**: "Access denied when calling Bedrock KnowledgeBase retrieve"
**Solution**: Ensure the agent IAM role has `bedrock:Retrieve` permission (included in Terraform)

#### 6. Ingestion Jobs Fail
**Problem**: Ingestion jobs fail or show 0 documents processed
**Solution**: 
- Verify S3 bucket permissions
- Check CSV file format and location
- Ensure knowledge base role has S3 access

#### 7. Stuck Resources During Teardown
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

#### 8. OpenSearch Collection Won't Delete
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

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔮 Next Steps

- [ ] Add more data sources to knowledge base
- [ ] Implement conversation memory
- [ ] Add API Gateway integration
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

### Common Operations
```bash
# 🏗️ Deploy everything
./deploy-complete.sh

# 🧪 Test functions with cities that have complete knowledge base data
./test-lambda.sh both Geneva

# 🔄 Update Lambda code only
./deploy-lambda.sh

# 📊 Check infrastructure status
terraform plan

# 🔥 Teardown options
./teardown-complete.sh      # Complete cleanup
./teardown-infrastructure.sh # Keep S3 data
./teardown-s3-only.sh       # Keep infrastructure

# 📦 Setup S3 only
./setup-knowledge-base-s3.sh

# 🆘 Recover lost state
./import-existing-resources.sh
```

### Teardown Quick Guide
```bash
# Scenario 1: Done with project permanently
./teardown-complete.sh

# Scenario 2: Pause project, keep data
./teardown-infrastructure.sh

# Scenario 3: Clean data, keep infrastructure  
./teardown-s3-only.sh

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