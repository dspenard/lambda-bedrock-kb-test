#!/bin/bash

# Complete teardown script for Bedrock Agent Test Bed
# This script will destroy ALL infrastructure and optionally clean up S3 data

set -e

echo "🔥 Complete Infrastructure Teardown"
echo "=================================="
echo ""
echo "This script will:"
echo "  1. Destroy all Terraform-managed infrastructure"
echo "  2. Optionally delete S3 bucket and data"
echo "  3. Clean up local files"
echo ""

# Check if terraform.tfstate exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No terraform.tfstate file found!"
    echo "   Either no infrastructure is deployed, or state file is missing."
    echo ""
    read -p "Continue with S3 cleanup only? (y/N): " continue_s3
    if [[ ! $continue_s3 =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
    SKIP_TERRAFORM=true
else
    SKIP_TERRAFORM=false
fi

# Confirm destruction
echo "⚠️  WARNING: This will permanently destroy all infrastructure!"
echo ""
if [ "$SKIP_TERRAFORM" = false ]; then
    echo "Resources to be destroyed:"
    terraform show -json | jq -r '.values.root_module.resources[]?.address' 2>/dev/null | sort || echo "  (Unable to list resources)"
    echo ""
fi

read -p "Are you sure you want to proceed? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""

# Step 1: Terraform Destroy
if [ "$SKIP_TERRAFORM" = false ]; then
    echo "🏗️ Step 1: Destroying Terraform infrastructure..."
    echo ""
    
    # Check if we have the S3 bucket name for conditional resources
    if [ -f "terraform.tfvars" ]; then
        echo "   Found terraform.tfvars - destroying all resources including knowledge base..."
    else
        echo "   No terraform.tfvars found - destroying core resources only..."
    fi
    
    terraform destroy -auto-approve
    
    if [ $? -eq 0 ]; then
        echo "✅ Terraform infrastructure destroyed successfully"
    else
        echo "❌ Terraform destroy failed - some resources may still exist"
        echo "   Check AWS console and clean up manually if needed"
    fi
else
    echo "🏗️ Step 1: Skipping Terraform destroy (no state file)"
fi

echo ""

# Step 2: S3 Cleanup (Optional)
echo "🪣 Step 2: S3 Bucket Cleanup"
echo ""

# Try to get bucket name from various sources
BUCKET_NAME=""
if [ -f ".kb-bucket-name" ]; then
    BUCKET_NAME=$(cat .kb-bucket-name)
elif [ -f "terraform.tfvars" ]; then
    BUCKET_NAME=$(grep knowledge_base_bucket_name terraform.tfvars | cut -d'"' -f2)
fi

if [ -n "$BUCKET_NAME" ]; then
    echo "   Found S3 bucket: $BUCKET_NAME"
    echo ""
    read -p "Delete S3 bucket and all data? (y/N): " delete_s3
    
    if [[ $delete_s3 =~ ^[Yy]$ ]]; then
        echo "   Deleting S3 bucket contents..."
        aws s3 rm s3://$BUCKET_NAME --recursive 2>/dev/null || echo "   (Bucket may already be empty)"
        
        echo "   Deleting S3 bucket..."
        aws s3 rb s3://$BUCKET_NAME 2>/dev/null || echo "   (Bucket may already be deleted)"
        
        echo "✅ S3 bucket cleanup completed"
    else
        echo "⏭️  S3 bucket preserved: $BUCKET_NAME"
        echo "   You can delete it manually later if needed"
    fi
else
    echo "   No S3 bucket found to clean up"
fi

echo ""

# Step 3: Local File Cleanup
echo "🧹 Step 3: Local File Cleanup"
echo ""

read -p "Clean up local configuration files? (y/N): " clean_local
if [[ $clean_local =~ ^[Yy]$ ]]; then
    echo "   Removing local files..."
    
    # Remove Terraform files
    rm -f terraform.tfstate*
    rm -f terraform.tfvars
    rm -f .kb-bucket-name
    rm -rf .terraform/
    
    # Remove generated files
    rm -f *.zip
    rm -f test_*.json
    rm -f response*.json
    
    echo "✅ Local files cleaned up"
else
    echo "⏭️  Local files preserved"
    echo "   You may want to keep terraform.tfstate for reference"
fi

echo ""
echo "🎉 Teardown Complete!"
echo ""
echo "Summary:"
if [ "$SKIP_TERRAFORM" = false ]; then
    echo "  ✅ Terraform infrastructure destroyed"
else
    echo "  ⏭️  Terraform infrastructure (skipped - no state file)"
fi

if [ -n "$BUCKET_NAME" ] && [[ $delete_s3 =~ ^[Yy]$ ]]; then
    echo "  ✅ S3 bucket deleted: $BUCKET_NAME"
elif [ -n "$BUCKET_NAME" ]; then
    echo "  ⏭️  S3 bucket preserved: $BUCKET_NAME"
else
    echo "  ℹ️  No S3 bucket found"
fi

if [[ $clean_local =~ ^[Yy]$ ]]; then
    echo "  ✅ Local files cleaned up"
else
    echo "  ⏭️  Local files preserved"
fi

echo ""
echo "💡 Next Steps:"
echo "   - Check AWS console to verify all resources are deleted"
echo "   - Review any remaining charges in AWS billing"
echo "   - Remove this project directory if no longer needed"