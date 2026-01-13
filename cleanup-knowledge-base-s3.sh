#!/bin/bash

# Cleanup S3 bucket for Bedrock Knowledge Base
# Removes all objects and deletes the bucket

set -e

# Check if bucket name file exists
if [ ! -f ".kb-bucket-name" ]; then
    echo "❌ No bucket name file found (.kb-bucket-name)"
    echo "   Please provide bucket name as argument: ./cleanup-knowledge-base-s3.sh <bucket-name>"
    echo "   Or run this from the directory where setup-knowledge-base-s3.sh was executed"
    exit 1
fi

# Read bucket name from file or use argument
BUCKET_NAME=${1:-$(cat .kb-bucket-name)}

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No bucket name provided"
    exit 1
fi

echo "🗑️  Cleaning up S3 bucket for Bedrock Knowledge Base..."
echo "   Bucket name: ${BUCKET_NAME}"
echo ""

# Confirm deletion
read -p "⚠️  Are you sure you want to delete bucket '${BUCKET_NAME}' and all its contents? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Check if bucket exists
if ! aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
    echo "❌ Bucket ${BUCKET_NAME} does not exist or is not accessible"
    exit 1
fi

# Remove all objects (including versions if versioning is enabled)
echo "🗂️  Removing all objects from bucket..."
aws s3 rm s3://${BUCKET_NAME} --recursive

# Remove all object versions if versioning is enabled
echo "🔄 Removing all object versions..."
aws s3api list-object-versions --bucket ${BUCKET_NAME} --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while read key version; do
    if [ ! -z "$key" ] && [ ! -z "$version" ]; then
        aws s3api delete-object --bucket ${BUCKET_NAME} --key "$key" --version-id "$version"
    fi
done

# Remove all delete markers
aws s3api list-object-versions --bucket ${BUCKET_NAME} --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text | while read key version; do
    if [ ! -z "$key" ] && [ ! -z "$version" ]; then
        aws s3api delete-object --bucket ${BUCKET_NAME} --key "$key" --version-id "$version"
    fi
done

# Delete the bucket
echo "🪣 Deleting bucket..."
aws s3 rb s3://${BUCKET_NAME}

if [ $? -eq 0 ]; then
    echo "✅ S3 bucket deleted successfully: ${BUCKET_NAME}"
    
    # Remove the bucket name file
    if [ -f ".kb-bucket-name" ]; then
        rm .kb-bucket-name
        echo "📝 Removed .kb-bucket-name file"
    fi
else
    echo "❌ Failed to delete S3 bucket"
    exit 1
fi

echo ""
echo "🎉 Knowledge Base S3 cleanup complete!"