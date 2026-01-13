#!/bin/bash

# Complete teardown script for Bedrock Agent Test Bed
# This script will destroy ALL infrastructure and optionally clean up S3 data

set -e

echo "🔥 Complete Infrastructure Teardown"
echo "=================================="
echo ""
echo "This script will:"
echo "  1. Automatically empty S3 bucket (if exists)"
echo "  2. Destroy all Terraform-managed infrastructure"
echo "  3. Optionally clean up legacy S3 buckets"
echo "  4. Clean up local files"
echo ""

# Check if terraform.tfstate exists
if [ ! -f "terraform/terraform.tfstate" ]; then
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
    cd terraform
    terraform show -json | jq -r '.values.root_module.resources[]?.address' 2>/dev/null | sort || echo "  (Unable to list resources)"
    cd ..
    echo ""
fi

read -p "Are you sure you want to proceed? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""

# Step 1: Empty S3 bucket before Terraform destroy
if [ "$SKIP_TERRAFORM" = false ]; then
    echo "🪣 Step 1: Preparing S3 bucket for deletion..."
    echo ""
    
    # Try to get bucket name from Terraform state
    cd terraform
    BUCKET_NAME=$(terraform output -raw s3_knowledge_base_bucket 2>/dev/null || echo "")
    cd ..
    
    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "" ]; then
        echo "   Found S3 bucket: $BUCKET_NAME"
        echo "   Emptying bucket contents..."
        
        # Delete all objects
        aws s3 rm s3://$BUCKET_NAME --recursive 2>/dev/null || echo "   (Bucket may already be empty)"
        
        # Delete all object versions (for versioned buckets)
        echo "   Deleting all object versions..."
        aws s3api delete-objects --bucket $BUCKET_NAME \
          --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME \
          --query '{Objects: Versions[].{Key: Key, VersionId: VersionId}}' --output json)" \
          2>/dev/null || echo "   (No versions to delete)"
        
        # Delete all delete markers
        echo "   Deleting delete markers..."
        aws s3api delete-objects --bucket $BUCKET_NAME \
          --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME \
          --query '{Objects: DeleteMarkers[].{Key: Key, VersionId: VersionId}}' --output json)" \
          2>/dev/null || echo "   (No delete markers to delete)"
        
        echo "✅ S3 bucket emptied successfully"
    else
        echo "   No S3 bucket found in Terraform state"
    fi
    echo ""
fi

# Step 2: Terraform Destroy
if [ "$SKIP_TERRAFORM" = false ]; then
    echo "🏗️ Step 2: Destroying Terraform infrastructure..."
    echo ""
    
    # Check if we have the S3 bucket name for conditional resources
    if [ -f "terraform/terraform.tfvars" ]; then
        echo "   Found terraform.tfvars - destroying all resources including knowledge base..."
    else
        echo "   No terraform.tfvars found - destroying core resources only..."
    fi
    
    cd terraform
    terraform destroy -auto-approve
    cd ..
    
    if [ $? -eq 0 ]; then
        echo "✅ Terraform infrastructure destroyed successfully"
    else
        echo "❌ Terraform destroy failed - some resources may still exist"
        echo "   Check AWS console and clean up manually if needed"
    fi
else
    echo "🏗️ Step 2: Skipping Terraform destroy (no state file)"
fi

echo ""

# Step 3: S3 Cleanup (Optional - for legacy buckets)
echo "🪣 Step 3: Legacy S3 Bucket Cleanup"
echo ""

# Try to get bucket name from various sources (for legacy deployments)
LEGACY_BUCKET_NAME=""
if [ -f ".kb-bucket-name" ]; then
    LEGACY_BUCKET_NAME=$(cat .kb-bucket-name)
elif [ -f "terraform/terraform.tfvars" ]; then
    LEGACY_BUCKET_NAME=$(grep knowledge_base_bucket_name terraform/terraform.tfvars | cut -d'"' -f2)
fi

if [ -n "$LEGACY_BUCKET_NAME" ]; then
    echo "   Found legacy S3 bucket: $LEGACY_BUCKET_NAME"
    echo ""
    read -p "Delete legacy S3 bucket and all data? (y/N): " delete_s3
    
    if [[ $delete_s3 =~ ^[Yy]$ ]]; then
        echo "   Deleting legacy S3 bucket contents..."
        aws s3 rm s3://$LEGACY_BUCKET_NAME --recursive 2>/dev/null || echo "   (Bucket may already be empty)"
        
        echo "   Deleting legacy S3 bucket..."
        aws s3 rb s3://$LEGACY_BUCKET_NAME 2>/dev/null || echo "   (Bucket may already be deleted)"
        
        echo "✅ Legacy S3 bucket cleanup completed"
    else
        echo "⏭️  Legacy S3 bucket preserved: $LEGACY_BUCKET_NAME"
        echo "   You can delete it manually later if needed"
    fi
else
    echo "   No legacy S3 bucket found to clean up"
fi

echo ""

# Step 4: Local File Cleanup
echo "🧹 Step 4: Local File Cleanup"
echo ""

read -p "Clean up local configuration files? (y/N): " clean_local
if [[ $clean_local =~ ^[Yy]$ ]]; then
    echo "   Removing local files..."
    
    # Remove Terraform files
    rm -f terraform/terraform.tfstate*
    rm -f .kb-bucket-name
    rm -rf terraform/.terraform/
    
    # Update terraform.tfvars to remove bucket reference but preserve the file
    if [ -f "terraform/terraform.tfvars" ]; then
        sed -i.bak '/knowledge_base_bucket_name/d' terraform/terraform.tfvars
        rm -f terraform/terraform.tfvars.bak
        echo "   Updated terraform.tfvars (removed bucket reference, preserved file)"
    fi
    
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
    echo "  ✅ S3 bucket automatically emptied before destruction"
    echo "  ✅ Terraform infrastructure destroyed"
else
    echo "  ⏭️  Terraform infrastructure (skipped - no state file)"
fi

if [ -n "$LEGACY_BUCKET_NAME" ] && [[ $delete_s3 =~ ^[Yy]$ ]]; then
    echo "  ✅ Legacy S3 bucket deleted: $LEGACY_BUCKET_NAME"
elif [ -n "$LEGACY_BUCKET_NAME" ]; then
    echo "  ⏭️  Legacy S3 bucket preserved: $LEGACY_BUCKET_NAME"
else
    echo "  ℹ️  No legacy S3 bucket found"
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