#!/bin/bash

# S3-only teardown script
# Deletes S3 bucket and data while preserving infrastructure

set -e

echo "🪣 S3 Data Teardown"
echo "=================="
echo ""

# Try to get bucket name from various sources
BUCKET_NAME=""
if [ -f ".kb-bucket-name" ]; then
    BUCKET_NAME=$(cat .kb-bucket-name)
    echo "Found bucket name from .kb-bucket-name: $BUCKET_NAME"
elif [ -f "terraform.tfvars" ]; then
    BUCKET_NAME=$(grep knowledge_base_bucket_name terraform.tfvars | cut -d'"' -f2 2>/dev/null)
    if [ -n "$BUCKET_NAME" ]; then
        echo "Found bucket name from terraform.tfvars: $BUCKET_NAME"
    fi
fi

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No S3 bucket name found!"
    echo ""
    echo "Bucket name sources checked:"
    echo "  - .kb-bucket-name file: $([ -f .kb-bucket-name ] && echo "exists but empty" || echo "not found")"
    echo "  - terraform.tfvars file: $([ -f terraform.tfvars ] && echo "exists but no bucket name" || echo "not found")"
    echo ""
    read -p "Enter S3 bucket name manually (or press Enter to exit): " manual_bucket
    
    if [ -z "$manual_bucket" ]; then
        echo "Exiting..."
        exit 1
    fi
    
    BUCKET_NAME="$manual_bucket"
fi

echo ""
echo "This script will:"
echo "  🔥 Delete all files in S3 bucket: $BUCKET_NAME"
echo "  🔥 Delete the S3 bucket itself"
echo "  ✅ Preserve all other infrastructure"
echo "  ✅ Keep local configuration files"
echo ""

# Verify bucket exists
echo "🔍 Verifying bucket exists..."
if ! aws s3 ls s3://$BUCKET_NAME >/dev/null 2>&1; then
    echo "❌ Bucket $BUCKET_NAME does not exist or is not accessible"
    echo "   Check your AWS credentials and bucket name"
    exit 1
fi

echo "✅ Bucket found and accessible"
echo ""

# Show bucket contents
echo "📋 Current bucket contents:"
aws s3 ls s3://$BUCKET_NAME --human-readable --summarize || echo "   (Unable to list contents)"
echo ""

# Confirm deletion
echo "⚠️  WARNING: This will permanently delete all data in the S3 bucket!"
read -p "Are you sure you want to delete bucket '$BUCKET_NAME' and all its contents? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "S3 teardown cancelled."
    exit 0
fi

echo ""
echo "🗑️ Deleting S3 bucket contents..."

# Delete all objects (including versions if versioning is enabled)
aws s3 rm s3://$BUCKET_NAME --recursive

if [ $? -eq 0 ]; then
    echo "✅ Bucket contents deleted"
else
    echo "⚠️  Some files may not have been deleted"
fi

echo ""
echo "🗑️ Deleting S3 bucket..."

# Delete the bucket itself
aws s3 rb s3://$BUCKET_NAME

if [ $? -eq 0 ]; then
    echo "✅ Bucket deleted successfully"
    
    # Clean up local references
    echo ""
    echo "🧹 Cleaning up local references..."
    
    read -p "Remove local bucket reference files? (y/N): " clean_refs
    if [[ $clean_refs =~ ^[Yy]$ ]]; then
        rm -f .kb-bucket-name
        
        # Update terraform.tfvars to remove bucket name
        if [ -f "terraform.tfvars" ]; then
            sed -i.bak '/knowledge_base_bucket_name/d' terraform.tfvars
            rm -f terraform.tfvars.bak
            echo "✅ Updated terraform.tfvars (removed bucket reference)"
        fi
        
        echo "✅ Local references cleaned up"
    else
        echo "⏭️  Local references preserved"
    fi
    
    echo ""
    echo "🎉 S3 teardown completed successfully!"
    echo ""
    echo "⚠️  Note: Your infrastructure still exists but knowledge base will not function"
    echo "   without S3 data. To restore:"
    echo "   1. Run: ./setup-knowledge-base-s3.sh"
    echo "   2. Run: terraform apply"
    
else
    echo "❌ Failed to delete bucket"
    echo "   The bucket may have remaining objects or dependencies"
    echo "   Check AWS console for details"
    exit 1
fi