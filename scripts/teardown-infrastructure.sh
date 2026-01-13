#!/bin/bash

# Infrastructure-only teardown script
# Destroys Terraform resources but preserves S3 data

set -e

echo "🏗️ Infrastructure Teardown (Preserving S3 Data)"
echo "=============================================="
echo ""

# Check if terraform.tfstate exists
if [ ! -f "terraform/terraform.tfstate" ]; then
    echo "❌ No terraform.tfstate file found!"
    echo "   No Terraform-managed infrastructure to destroy."
    exit 1
fi

echo "This script will:"
echo "  ✅ Destroy all Terraform-managed infrastructure"
echo "  ✅ Preserve S3 bucket and data"
echo "  ✅ Keep local configuration files"
echo ""

# Show what will be destroyed
echo "Resources to be destroyed:"
cd terraform
terraform show -json | jq -r '.values.root_module.resources[]?.address' 2>/dev/null | sort || echo "  (Unable to list resources)"
cd ..
echo ""

# Confirm destruction
read -p "Proceed with infrastructure teardown? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "🔥 Destroying Terraform infrastructure..."
echo ""

cd terraform
terraform destroy -auto-approve
cd ..

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Infrastructure teardown completed successfully!"
    echo ""
    echo "Preserved:"
    
    if [ -f ".kb-bucket-name" ]; then
        BUCKET_NAME=$(cat .kb-bucket-name)
        echo "  📦 S3 bucket: $BUCKET_NAME"
        echo "  📄 Knowledge base data files"
    fi
    
    echo "  📋 terraform.tfvars"
    echo "  📋 .kb-bucket-name"
    echo "  📋 terraform.tfstate (for reference)"
    echo ""
    echo "💡 To redeploy:"
    echo "   terraform apply"
    echo ""
    echo "💡 To completely clean up:"
    echo "   ./teardown-complete.sh"
else
    echo ""
    echo "❌ Infrastructure teardown failed!"
    echo "   Some resources may still exist - check AWS console"
    exit 1
fi