#!/bin/bash

# Check status of S3 bucket for Bedrock Knowledge Base
# Shows bucket info, contents, and configuration

set -e

# Check if bucket name file exists
if [ ! -f ".kb-bucket-name" ]; then
    echo "❌ No bucket name file found (.kb-bucket-name)"
    echo "   Please provide bucket name as argument: ./check-knowledge-base-s3.sh <bucket-name>"
    exit 1
fi

# Read bucket name from file or use argument
BUCKET_NAME=${1:-$(cat .kb-bucket-name)}

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No bucket name provided"
    exit 1
fi

echo "🔍 Checking S3 bucket for Bedrock Knowledge Base..."
echo "   Bucket name: ${BUCKET_NAME}"
echo ""

# Check if bucket exists
if ! aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
    echo "❌ Bucket ${BUCKET_NAME} does not exist or is not accessible"
    exit 1
fi

# Get bucket location
REGION=$(aws s3api get-bucket-location --bucket ${BUCKET_NAME} --query 'LocationConstraint' --output text)
if [ "$REGION" = "None" ]; then
    REGION="us-east-1"
fi

echo "📍 Bucket Region: ${REGION}"

# Check versioning status
VERSIONING=$(aws s3api get-bucket-versioning --bucket ${BUCKET_NAME} --query 'Status' --output text)
echo "🔄 Versioning: ${VERSIONING:-Disabled}"

# List bucket contents
echo ""
echo "📂 Bucket Contents:"
aws s3 ls s3://${BUCKET_NAME}/ --human-readable --summarize

# Get bucket size
echo ""
echo "📊 Bucket Statistics:"
aws s3 ls s3://${BUCKET_NAME} --recursive --human-readable --summarize | tail -2

# Check public access settings
echo ""
echo "🔒 Public Access Block Configuration:"
aws s3api get-public-access-block --bucket ${BUCKET_NAME} --query 'PublicAccessBlockConfiguration' --output table 2>/dev/null || echo "   No public access block configuration found"

echo ""
echo "🔗 Bucket Information:"
echo "   Bucket Name: ${BUCKET_NAME}"
echo "   Region: ${REGION}"
echo "   ARN: arn:aws:s3:::${BUCKET_NAME}"
echo "   Console URL: https://s3.console.aws.amazon.com/s3/buckets/${BUCKET_NAME}?region=${REGION}"

echo ""
echo "💡 For Terraform data reference:"
echo "   data \"aws_s3_bucket\" \"knowledge_base\" {"
echo "     bucket = \"${BUCKET_NAME}\""
echo "   }"