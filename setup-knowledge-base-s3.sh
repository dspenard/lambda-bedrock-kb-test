#!/bin/bash

# Setup S3 bucket for Bedrock Knowledge Base
# Creates bucket with random suffix and uploads CSV files

set -e

# Generate random suffix (8 characters)
RANDOM_SUFFIX=$(openssl rand -hex 4)
BUCKET_NAME="bedrock-kb-${RANDOM_SUFFIX}"
REGION="us-east-1"

echo "🪣 Setting up S3 bucket for Bedrock Knowledge Base..."
echo "   Bucket name: ${BUCKET_NAME}"
echo "   Region: ${REGION}"
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

# Create terraform.tfvars file with the bucket name
echo "knowledge_base_bucket_name = \"${BUCKET_NAME}\"" > terraform.tfvars
echo "📝 Terraform variables file created: terraform.tfvars"