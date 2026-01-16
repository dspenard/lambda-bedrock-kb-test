#!/bin/bash

# Script to display Cognito configuration for frontend

echo "🔐 Cognito Configuration"
echo "========================"
echo ""

cd terraform

USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
CLIENT_ID=$(terraform output -raw cognito_client_id 2>/dev/null)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

if [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
    echo "❌ Error: Could not retrieve Cognito configuration"
    echo "   Make sure Terraform has been applied successfully"
    exit 1
fi

echo "User Pool ID:     $USER_POOL_ID"
echo "Client ID:        $CLIENT_ID"
echo "Region:           $REGION"
echo ""
echo "✅ Configuration is already set in frontend/src/aws-config.js"
echo ""
echo "📝 To create a test user, run:"
echo "   aws cognito-idp admin-create-user \\"
echo "     --user-pool-id $USER_POOL_ID \\"
echo "     --username test@example.com \\"
echo "     --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true \\"
echo "     --temporary-password TempPass123! \\"
echo "     --message-action SUPPRESS"
