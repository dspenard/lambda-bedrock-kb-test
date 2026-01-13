#!/bin/bash

# Setup S3 bucket for Bedrock Knowledge Base
# Creates bucket with random suffix and uploads CSV files
# Supports optional 3-character prefix for multi-developer/environment usage

set -e

#!/bin/bash

# Setup S3 bucket for Bedrock Knowledge Base
# Creates bucket with random suffix and uploads CSV files
# Supports optional 3-character prefix for multi-developer/environment usage
#
# Usage:
#   ./setup-knowledge-base-s3.sh           # No prefix (default)
#   ./setup-knowledge-base-s3.sh jd        # With developer initials
#   ./setup-knowledge-base-s3.sh dev       # With environment name

set -e

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [PREFIX]"
    echo ""
    echo "Setup S3 bucket for Bedrock Knowledge Base with optional prefix"
    echo ""
    echo "Arguments:"
    echo "  PREFIX    Optional 1-3 character prefix (lowercase alphanumeric)"
    echo ""
    echo "Examples:"
    echo "  $0           # Creates: bedrock-kb-xxxxxxxx"
    echo "  $0 jd        # Creates: jd-bedrock-kb-xxxxxxxx"
    echo "  $0 dev       # Creates: dev-bedrock-kb-xxxxxxxx"
    echo "  $0 sm1       # Creates: sm1-bedrock-kb-xxxxxxxx"
    echo ""
    echo "The prefix helps avoid resource name collisions when multiple"
    echo "developers or environments use the same AWS account."
    exit 0
fi

# Check for optional prefix argument
PREFIX=""
if [ $# -eq 1 ]; then
    PREFIX="$1"
    # Validate prefix format (1-3 lowercase alphanumeric characters)
    if [[ ! $PREFIX =~ ^[a-z0-9]{1,3}$ ]]; then
        echo "❌ Invalid prefix format. Must be 1-3 lowercase alphanumeric characters."
        echo "   Examples: 'jd', 'dev', 'sm1'"
        echo "   Use '$0 --help' for more information."
        exit 1
    fi
    echo "🏷️  Using prefix: ${PREFIX}"
elif [ $# -gt 1 ]; then
    echo "❌ Too many arguments. Expected 0 or 1 argument."
    echo "   Use '$0 --help' for usage information."
    exit 1
fi

# Generate random suffix (8 characters)
RANDOM_SUFFIX=$(openssl rand -hex 4)

# Create bucket name with optional prefix
if [ -n "$PREFIX" ]; then
    BUCKET_NAME="${PREFIX}-bedrock-kb-${RANDOM_SUFFIX}"
else
    BUCKET_NAME="bedrock-kb-${RANDOM_SUFFIX}"
fi

REGION="us-east-1"

echo "🪣 Setting up S3 bucket for Bedrock Knowledge Base..."
echo "   Bucket name: ${BUCKET_NAME}"
echo "   Region: ${REGION}"
if [ -n "$PREFIX" ]; then
    echo "   Prefix: ${PREFIX}"
fi
echo ""

# Create S3 bucket
echo "📦 Creating S3 bucket..."
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

if [ $? -eq 0 ]; then
    echo "✅ S3 bucket created successfully: s3://${BUCKET_NAME}"
else
    echo "❌ Failed to create S3 bucket"
    exit 1
fi

# Enable versioning (recommended for knowledge bases)
echo "🔄 Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

# Upload CSV files
echo ""
echo "📤 Uploading knowledge base CSV files..."

# Check if CSV files exist
if [ ! -f "data/knowledge-base/world_cities_air_quality_water_pollution_2021.csv" ]; then
    echo "❌ File not found: world_cities_air_quality_water_pollution_2021.csv"
    exit 1
fi

if [ ! -f "data/knowledge-base/world_cities_cost_of_living_2018.csv" ]; then
    echo "❌ File not found: world_cities_cost_of_living_2018.csv"
    exit 1
fi

# Upload air quality data
echo "  → Uploading air quality and water pollution data..."
aws s3 cp data/knowledge-base/world_cities_air_quality_water_pollution_2021.csv \
    s3://${BUCKET_NAME}/world_cities_air_quality_water_pollution_2021.csv

# Upload cost of living data
echo "  → Uploading cost of living data..."
aws s3 cp data/knowledge-base/world_cities_cost_of_living_2018.csv \
    s3://${BUCKET_NAME}/world_cities_cost_of_living_2018.csv

# Verify uploads
echo ""
echo "🔍 Verifying uploads..."
aws s3 ls s3://${BUCKET_NAME}/ --human-readable --summarize

echo ""
echo "🎉 Knowledge Base S3 setup complete!"
echo ""
echo "📋 Summary:"
echo "   Bucket Name: ${BUCKET_NAME}"
echo "   Region: ${REGION}"
echo "   Files Uploaded: 2 CSV files"
echo "   Versioning: Enabled"
echo ""
echo "💡 Next Steps:"
echo "   1. Use this bucket name in your Terraform knowledge base configuration"
echo "   2. Reference: s3://${BUCKET_NAME}"
echo "   3. Add this bucket name to your terraform variables or data sources"
echo ""
echo "🔗 Bucket ARN: arn:aws:s3:::${BUCKET_NAME}"

# Save bucket name to file for reference
echo ${BUCKET_NAME} > .kb-bucket-name
echo "📝 Bucket name saved to .kb-bucket-name file for reference"

# Create or update terraform.tfvars file with the bucket name and prefix
if [ -n "$PREFIX" ]; then
    # Check if terraform.tfvars exists
    if [ -f "terraform.tfvars" ]; then
        # Remove any existing bucket name line and add new ones
        sed -i.bak '/knowledge_base_bucket_name/d' terraform.tfvars
        sed -i.bak '/resource_prefix/d' terraform.tfvars
        rm -f terraform.tfvars.bak
        echo "" >> terraform.tfvars
        echo "# S3 bucket name (auto-generated by setup-knowledge-base-s3.sh)" >> terraform.tfvars
        echo "knowledge_base_bucket_name = \"${BUCKET_NAME}\"" >> terraform.tfvars
        echo "resource_prefix = \"${PREFIX}\"" >> terraform.tfvars
        echo "📝 Updated terraform.tfvars with bucket name and prefix: ${PREFIX}"
    else
        cat > terraform.tfvars << EOF
knowledge_base_bucket_name = "${BUCKET_NAME}"
resource_prefix = "${PREFIX}"
EOF
        echo "📝 Created terraform.tfvars with bucket name and prefix: ${PREFIX}"
    fi
else
    # Check if terraform.tfvars exists
    if [ -f "terraform.tfvars" ]; then
        # Remove any existing bucket name line and add new one
        sed -i.bak '/knowledge_base_bucket_name/d' terraform.tfvars
        rm -f terraform.tfvars.bak
        echo "" >> terraform.tfvars
        echo "# S3 bucket name (auto-generated by setup-knowledge-base-s3.sh)" >> terraform.tfvars
        echo "knowledge_base_bucket_name = \"${BUCKET_NAME}\"" >> terraform.tfvars
        echo "📝 Updated terraform.tfvars with bucket name"
    else
        echo "knowledge_base_bucket_name = \"${BUCKET_NAME}\"" > terraform.tfvars
        echo "📝 Created terraform.tfvars with bucket name"
    fi
fi