# Deployment and Teardown Guide

Complete guide for deploying and tearing down the Bedrock Agent Test Bed infrastructure.

---

## 📚 Table of Contents

- [Quick Start](#-quick-start)
- [Prerequisites and Requirements](#-prerequisites-and-requirements)
- [AWS Access and Permissions](#-aws-access-and-permissions-requirements)
- [Configuration](#️-configuration)
  - [terraform.tfvars Setup](#-terraformtfvars-setup-optional)
  - [Resource Prefix Options](#️-resource-prefix-option-examples)
  - [Knowledge Base Deployment Options](#-knowledge-base-deployment-options)
  - [OpenSearch Access Configuration](#-opensearch-access-configuration)
  - [Terraform State Management](#️-terraform-state-management)
- [Deployment Options](#-deployment-options)
  - [Simplified Deployment (Recommended)](#-simplified-deployment-recommended)
  - [Resource Prefixing](#️-resource-prefixing-for-multi-developer-environments)
  - [Legacy Deployment](#option-2-legacy-deployment-external-s3-management)
  - [Manual Step-by-Step Deployment](#option-3-manual-step-by-step-deployment)
- [Teardown and Cleanup](#-teardown-and-cleanup)
  - [Complete Teardown](#1-complete-teardown-recommended-for-final-cleanup)
  - [Infrastructure-Only Teardown](#2-infrastructure-only-teardown)
  - [S3-Only Teardown](#3-s3-only-teardown)
  - [Manual Teardown](#4-manual-teardown-advanced-users)

---

## 🚀 Quick Start

If you're anxious to get started and you're up to speed on npm, Git, Python, Terraform, and AWS CLI and setting its credentials, then follow these steps for a complete deployment in about 10 minutes.  Otherwise, go to the [Prerequisites and Requirements](#-prerequisites-and-requirements) section and follow along.

### Prerequisites
- **Git** - Clone the repository
- **Terraform** (>= 1.0) - Infrastructure as code
- **Python 3** (>= 3.8) - Required for OpenSearch index creation; install `opensearch-py` and `boto3` packages
- **Node.js and npm** (>= 14.x) - Required for React frontend
- **AWS Account** - Admin access (for ease of use, recommended for running this PoC)
- **AWS CLI** (>= 2.0) - Configured with credentials for your chosen AWS Account; set region to us-east-1

### Deploy Everything
```bash
# 1. Clone and enter the project
git clone https://github.com/dspenard/lambda-bedrock-kb-test.git && cd lambda-bedrock-kb-test

# 2. Deploy the complete stack (Lambda, Agent, Knowledge Base, OpenSearch)
./scripts/deploy-complete.sh

# 3. Test the deployment
./scripts/test-lambda.sh both Geneva
```

**That's it!** The deployment script automatically:
- Initializes Terraform
- Creates all AWS resources (Lambda, Bedrock Agent, Knowledge Base, OpenSearch, S3)
- Uploads knowledge base data
- Configures everything for immediate use

### Test Your Deployment

Try different cities to see how the agent combines knowledge base data with general facts:

```bash
# Test cities with rich knowledge base data
./scripts/test-lambda.sh both Geneva
./scripts/test-lambda.sh agent Tokyo
./scripts/test-lambda.sh direct Berlin
```

**See the main [README Testing section](../README.md#-testing) for more examples and detailed testing options.**

### Teardown Everything
```bash
# Remove all AWS resources and avoid ongoing charges
./scripts/teardown-complete.sh
```

**Cost**: ~$200/month if left running (primarily OpenSearch Serverless). Teardown removes all charges.

**💡 Vector Storage Note**: OpenSearch Serverless was chosen for this PoC due to ease of setup and being fully managed, but it is **extremely expensive** (~$175-$700/month depending on configuration). An S3 vector store option will be added soon as a more cost-effective alternative. For production deployments, consider alternatives like Amazon Aurora PostgreSQL with pgvector, Amazon S3 Vectors, or third-party options like Pinecone.

---

## 📋 Prerequisites and Requirements

Before deploying this project, ensure you have the following tools installed and configured:

### 🛠️ Required Tools

#### 1. **Terraform** (>= 1.0)
Infrastructure as Code tool for managing AWS resources.

**Installation:**
```bash
# macOS (using Homebrew)
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform --version
```

**Alternative:** Download from [terraform.io](https://www.terraform.io/downloads)

#### 2. **AWS CLI** (>= 2.0)
Command-line interface for interacting with AWS services.

**Installation:**
```bash
# macOS (using Homebrew)
brew install awscli

# Windows (using installer)
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi

# Linux (using pip)
pip install awscli

# Linux (using package manager)
sudo apt install awscli  # Ubuntu/Debian
sudo yum install awscli  # CentOS/RHEL

# Verify installation
aws --version
```

**Alternative:** Download from [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

#### 3. **Git**
Version control system for cloning the repository.

**Installation:**
```bash
# macOS (using Homebrew)
brew install git

# Windows
# Download from: https://git-scm.com/download/win

# Linux
sudo apt install git      # Ubuntu/Debian
sudo yum install git      # CentOS/RHEL

# Verify installation
git --version
```

#### 4. **Python 3** (>= 3.8)
Required for OpenSearch index creation script.

**Installation:**
```bash
# macOS (using Homebrew)
brew install python3

# Windows
# Download from: https://www.python.org/downloads/

# Linux (usually pre-installed)
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo yum install python3 python3-pip  # CentOS/RHEL

# Verify installation
python3 --version
pip3 --version
```

**Required Python packages:**
```bash
# Install required packages for OpenSearch index creation
pip3 install opensearch-py boto3

# On macOS, you may need to use --break-system-packages flag
pip3 install --break-system-packages opensearch-py boto3
```

#### 5. **Node.js and npm** (>= 14.x)
Required for React frontend (when `enable_frontend = true` - default).

**Installation:**
```bash
# macOS (using Homebrew)
brew install node

# Windows
# Download from: https://nodejs.org/

# Linux (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

**Note:** If you're deploying backend-only (`enable_frontend = false`), Node.js is not required.

### 🔧 Optional Tools (Recommended)

#### **jq** - JSON processor for testing
```bash
# macOS
brew install jq

# Linux
sudo apt install jq      # Ubuntu/Debian
sudo yum install jq      # CentOS/RHEL

# Windows
# Download from: https://stedolan.github.io/jq/download/
```

#### **curl** - For API testing (usually pre-installed)
```bash
# Verify installation
curl --version
```

### 📝 Development Notes

**System Tools**: The setup scripts use common system tools (`unzip`, `wget`, `curl`) that are typically pre-installed on most systems.

### ✅ Verification Checklist

Run these commands to verify all prerequisites are installed:

```bash
# Check Terraform
terraform --version
# Expected: Terraform v1.0+ 

# Check AWS CLI
aws --version
# Expected: aws-cli/2.0+

# Check Git
git --version
# Expected: git version 2.0+

# Check Python 3
python3 --version
# Expected: Python 3.8+

# Check Python packages
pip3 list | grep -E "opensearch-py|boto3"
# Expected: opensearch-py and boto3 listed

# Check Node.js (if using frontend)
node --version
# Expected: v14.0+

# Check npm (if using frontend)
npm --version
# Expected: 6.0+

# Check AWS credentials (after configuration)
aws sts get-caller-identity
# Expected: JSON with your AWS account info

# Optional: Check jq
jq --version
# Expected: jq-1.6+
```

### 🚨 Common Installation Issues

**Terraform not found:**
- Ensure Terraform binary is in your system PATH
- Try restarting your terminal after installation

**AWS CLI not configured:**
- Run `aws configure` to set up credentials
- Ensure you have appropriate AWS permissions (see Configuration section)

**Permission denied errors:**
- On macOS/Linux, you may need to use `sudo` for system-wide installation
- Consider using package managers (Homebrew, apt, yum) instead of manual installation

### 🎯 Quick Setup Script

For macOS users with Homebrew:
```bash
# Install all prerequisites at once
brew install terraform awscli git python3 node jq

# Install Python packages
pip3 install --break-system-packages opensearch-py boto3

# Verify installations
terraform --version && aws --version && git --version && python3 --version && node --version && jq --version
```

For Ubuntu/Debian users:
```bash
# Update package list
sudo apt update

# Install prerequisites
sudo apt install -y git curl jq python3 python3-pip

# Install Python packages
pip3 install opensearch-py boto3

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

---

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

### Required AWS Permissions

This project requires extensive AWS permissions to create and manage multiple services.

**For Development/Testing (Easiest):**
- Use an IAM user or role with the **`AdministratorAccess`** managed policy
- This is the quickest path for PoC and learning environments
- Eliminates permission-related deployment issues
- Use with caution, as least-privilege is best practice

**For Production and not running locally for testing (Least-Privilege):**
- Create a custom IAM role with only the specific permissions listed in the policy statement below
- Assign this role to your IAM user
- Follows AWS security best practices for minimal required access

#### 🔒 Least-Privilege IAM Policy

For production environments or when you need least-privilege access, create a custom IAM role with this policy and assign it to your user:

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

#### 📋 Detailed Permission Breakdown

The following AWS services and permissions are required:

**Core Infrastructure Permissions:**
- **IAM**: Create and manage roles, policies, and policy attachments
- **Lambda**: Create, update, and invoke functions
- **CloudWatch**: Create and manage log groups
- **S3**: Create buckets, upload objects, and manage bucket policies

**Bedrock Permissions:**
- **Bedrock**: Access to foundation models, create agents, knowledge bases, and data sources
- **Bedrock Agent**: Create and manage agents, action groups, and knowledge base associations
- **Bedrock Runtime**: Invoke models and retrieve from knowledge bases

**OpenSearch Serverless Permissions:**
- **OpenSearch Serverless**: Create collections, security policies, and access policies
- **OpenSearch**: Create and manage vector indices

### AWS Region Requirements

This project is configured for **us-east-1** region. Ensure your AWS CLI is configured for this region:

```bash
# Check current region
aws configure get region

# Set region if needed
aws configure set region us-east-1
```

### Bedrock Model Access

AWS Bedrock now enables most foundation models by default, including the models used in this project:
- `Claude 3 Haiku` (anthropic.claude-3-haiku-20240307-v1:0)
- `Amazon Titan Text Embeddings` (amazon.titan-embed-text-v1)

**Verify access** (optional):
```bash
# List available models
aws bedrock list-foundation-models --region us-east-1

# Check specific model access
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-haiku-20240307-v1:0 \
  --region us-east-1
```

If you encounter access issues, go to **AWS Console → Bedrock → Model Access** for additional information.

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

---

## ⚙️ Configuration

### 🔧 terraform.tfvars Setup (Optional)

The `terraform.tfvars` file is **optional**. Terraform will use defaults if this file doesn't exist:
- No resource prefix (resources named `bedrock-agent-testbed-*`)
- **Knowledge base ENABLED by default** with Terraform-managed S3 bucket
- Region: us-east-1
- OpenSearch access includes current user

To customize your deployment, create a configuration file:

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your preferences
# terraform.tfvars (git-ignored)
resource_prefix = "dts"                                   # Your 3-char prefix (optional)
enable_knowledge_base = true                              # Enable Terraform-managed S3 & knowledge base (default: true)
include_current_user_in_opensearch_access = true          # Include current user in OpenSearch access (default: true)
```

### 🏷️ Resource Prefix Option Examples

| Prefix | Use Case | Example Resources |
|--------|----------|-------------------|
| `dts` | Developer initials | `dts-bedrock-agent-testbed-city-facts-direct` |
| `dev` | Development environment | `dev-bedrock-agent-testbed-city-facts-direct` |
| `stg` | Staging environment | `stg-bedrock-agent-testbed-city-facts-direct` |
| _(none)_ | Default | `bedrock-agent-testbed-city-facts-direct` |

### 📦 Knowledge Base Deployment Options

| Option | Configuration | S3 Management | Use Case |
|--------|---------------|---------------|----------|
| **Terraform-Managed** (Default) | `enable_knowledge_base = true` | Automatic | New deployments (recommended, enabled by default) |
| **External S3** | `knowledge_base_bucket_name = "bucket"` | Manual scripts | Existing buckets |
| **Core Only** | `enable_knowledge_base = false` | None | Lambda + Agent only (no KB) |

### 🔐 OpenSearch Access Configuration

Controls whether your current AWS user/role is included in the OpenSearch access policy. The knowledge base service role always has access regardless of this setting.

```bash
# terraform.tfvars
include_current_user_in_opensearch_access = true   # Default: true
```

- **`true` (default)**: Adds your current user for development, debugging, and manual operations
- **`false`**: Production mode - restricts access to service roles only for better security

### ⚠️ Terraform State Management

**CRITICAL**: The `terraform.tfstate` file contains the mapping between your Terraform configuration and your actual AWS resources. **Never delete or lose this file!**

- ✅ **Keep it safe**: Back up your `terraform.tfstate` file regularly
- ✅ **Don't commit it**: The `.gitignore` file excludes it from version control (contains sensitive data)
- ❌ **Never delete**: If lost, you'll need to manually import all resources (see `import-existing-resources.sh`)

**Note**: This project uses **local state** for simplicity (POC/demo purposes). For production or team environments, always use **remote state management**:

**Recommended Remote State Options:**
- **AWS S3 + DynamoDB** - Industry standard, state locking, versioning ([Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3))
- **Terraform Cloud** - Free tier available, built-in collaboration and state management
- **Terraform Enterprise** - Self-hosted, advanced governance and policy enforcement
- **Other Cloud Providers** - Azure Blob Storage, Google Cloud Storage, Consul, etc.

Remote state provides:
- **Team collaboration** - Multiple developers can work safely
- **State locking** - Prevents concurrent modifications
- **Encryption** - State data encrypted at rest and in transit
- **Versioning** - Roll back to previous states if needed
- **Audit logging** - Track who made what changes

---

## 🚀 Deployment Options

**💡 Deployment Method Guide:**
- **New deployments**: Use "Simplified Deployment" (recommended) - Terraform manages everything including S3
- **Existing external S3 buckets**: Use "Legacy Deployment" - For deployments with pre-existing S3 buckets
- **Learning/debugging**: Use "Manual Step-by-Step" - Understand each deployment phase

---

### 🎯 Simplified Deployment (Recommended)

The easiest way to deploy everything, including Terraform-managed S3 and automatic file uploads of sample city data needed for the knowledge base:

```bash
# Clone and navigate to the project
git clone https://github.com/dspenard/lambda-bedrock-kb-test.git && cd lambda-bedrock-kb-test

# Deploy everything with one command (no prefix)
./scripts/deploy-complete.sh

# OR deploy with a 3-character prefix for multi-developer environments
# ./scripts/deploy-complete.sh dts  # Using your initials
# ./scripts/deploy-complete.sh dev  # Using environment name
```

This single command will:
1. ✅ Initialize Terraform
2. ✅ Create all infrastructure (Lambda, IAM, Bedrock Agent, API Gateway, Cognito)
3. ✅ Create S3 bucket with proper naming
4. ✅ Upload knowledge base CSV files automatically
5. ✅ Create OpenSearch Serverless collection
6. ✅ Create Bedrock knowledge base with data sources
7. ✅ Associate everything together
8. ✅ Deploy React frontend (if enabled - default)
9. ✅ Provide test commands for immediate use

**Total deployment time**: ~5-10 minutes

**Frontend Deployment**: By default, the full-stack mode is enabled (`enable_frontend = true`), which deploys:
- API Gateway REST API with Cognito authorization
- Cognito User Pool for authentication
- React frontend (runs locally on port 3000)

To deploy backend-only (no frontend), set `enable_frontend = false` in `terraform.tfvars`.

### 🏷️ Resource Prefixing for Multi-Developer Environments

This project supports optional 3-character prefixes to avoid resource name collisions that can occur if multiple develpers are using the same AWS account:

```bash
# Deploy with developer initials
./scripts/deploy-complete.sh dts   # Creates: dts-bedrock-agent-testbed-*

# Deploy with environment name  
./scripts/deploy-complete.sh dev   # Creates: dev-bedrock-agent-testbed-*

# Deploy without prefix (default)
./scripts/deploy-complete.sh       # Creates: bedrock-agent-testbed-*
```

**Benefits:**
- Multiple developers can deploy to the same AWS account
- Environment isolation (dev, staging, prod)
- Easy resource identification and cost tracking

### Option 2: Legacy Deployment (External S3 Management)

For existing deployments or when you need external S3 bucket management:

For a completely automated deployment, use the provided script:

```bash
# Clone and navigate to the project
git clone https://github.com/dspenard/lambda-bedrock-kb-test.git && cd lambda-bedrock-kb-test

# Run the complete deployment script
./scripts/deploy-complete.sh
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

### 🔧 Configuration Options

#### Option 1: Terraform-Managed S3 (Default)
Set `enable_knowledge_base = true` in your `terraform.tfvars`:

```hcl
# terraform.tfvars
resource_prefix = "dts"          # Optional 3-char prefix
enable_knowledge_base = true     # Enable Terraform-managed S3
```

#### Option 2: External S3 Bucket
Use the legacy setup script and reference existing bucket:

```bash
./scripts/setup-knowledge-base-s3.sh dts  # Creates external S3 bucket
# terraform.tfvars will be updated automatically
```

### Option 3: Manual Step-by-Step Deployment

For advanced users who want full control over each step:

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed
- `jq` for JSON processing (optional, for testing)

### ⚠️ Important: Terraform State Management

**CRITICAL**: The `terraform.tfstate` file contains the mapping between your Terraform configuration and your actual AWS resources. **Never delete or lose this file!**

- ✅ **Keep it safe**: Back up your `terraform.tfstate` file regularly
- ✅ **Don't commit it**: The `.gitignore` file excludes it from version control (contains sensitive data)
- ❌ **Never delete**: If lost, you'll need to manually import all resources (see `import-existing-resources.sh`)

**Note**: This project uses **local state** for simplicity (POC/demo purposes). For production or team environments, always use **remote state management**:

**Recommended Remote State Options:**
- **AWS S3 + DynamoDB** - Industry standard, state locking, versioning ([Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3))
- **Terraform Cloud** - Free tier available, built-in collaboration and state management
- **Terraform Enterprise** - Self-hosted, advanced governance and policy enforcement
- **Other Cloud Providers** - Azure Blob Storage, Google Cloud Storage, etc.

Remote state provides:
- **Team collaboration** - Multiple developers can work safely
- **State locking** - Prevents concurrent modifications
- **Encryption** - State data encrypted at rest and in transit
- **Versioning** - Roll back to previous states if needed
- **Audit logging** - Track who made what changes

### Configuration Files

This project uses several configuration files:

1. **`terraform.tfvars`** - Contains your S3 bucket name (created by `setup-knowledge-base-s3.sh`)
   ```hcl
   knowledge_base_bucket_name = "bedrock-kb-xxxxxxxx"
   ```

2. **`.kb-bucket-name`** - Backup reference file with S3 bucket name (legacy/external S3 deployments only)

3. **`terraform.tfstate`** - **CRITICAL** - Contains your infrastructure state mapping

**Note**: The knowledge base components are conditional - they only deploy when `knowledge_base_bucket_name` is provided in `terraform.tfvars`.

### Step 1: Initial Infrastructure Setup
```bash
# Clone and navigate to the project
git clone https://github.com/dspenard/lambda-bedrock-kb-test.git && cd lambda-bedrock-kb-test

# Initialize Terraform
terraform init

# Deploy core infrastructure (Lambda functions, IAM roles, Bedrock agent)
terraform apply
```

### Step 2: Knowledge Base S3 Setup
```bash
# Create S3 bucket and upload knowledge base data
./scripts/setup-knowledge-base-s3.sh

# This script will:
# - Create a uniquely named S3 bucket (bedrock-kb-xxxxxxxx)
# - Upload both CSV files to the bucket
# - Create terraform.tfvars with the bucket name
# - Create .kb-bucket-name as a backup reference

# Verify upload
./scripts/check-knowledge-base-s3.sh
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

---

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
./scripts/teardown-complete.sh
```

**Interactive Process:**
1. **Confirmation**: Script shows all resources to be destroyed
2. **S3 Auto-Empty**: Automatically empties S3 bucket before destruction
3. **Infrastructure**: Destroys all Terraform-managed resources
4. **Legacy S3 Cleanup**: Asks if you want to delete any legacy S3 buckets
5. **Local Files**: Asks if you want to clean up configuration files

**What gets destroyed:**
- ✅ All Lambda functions and IAM roles
- ✅ Bedrock agent and action groups
- ✅ Knowledge base and data sources
- ✅ OpenSearch Serverless collection
- ✅ CloudWatch log groups
- ✅ S3 bucket and data (automatically emptied)
- ✅ Local configuration files (optional)

**Features:**
- **Automatic S3 Emptying**: No more "bucket not empty" errors
- **Handles Versioned Buckets**: Deletes all versions and delete markers
- **Dynamic Bucket Detection**: Gets bucket name from Terraform state
- **Error-Free Teardown**: Smooth destruction process

**Estimated time:** 5-10 minutes (OpenSearch deletion is slow)

**Cost impact:** Eliminates all ongoing charges

---

### 2. Infrastructure-Only Teardown

**Command:**
```bash
./scripts/teardown-infrastructure.sh
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
./scripts/teardown-s3-only.sh
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
- OpenSearch Serverless: ~$0.24/hour per OCU (~$175/month per OCU, typically 1-4 OCUs)
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
./scripts/deploy-complete.sh  # Full redeployment needed
```

**After S3-Only Teardown:**
```bash
./scripts/setup-knowledge-base-s3.sh  # Recreate S3 bucket
terraform apply                        # Update knowledge base
```

---

## 🔙 Back to Main Documentation

Return to the [main README](../README.md) for architecture overview, testing, and other documentation.
