# Frontend Deployment Guide

This guide explains how to enable or disable the frontend components (API Gateway + Cognito) in your deployment.

## Overview

The project supports two deployment modes:

1. **Backend-only** (default): Lambda functions + Bedrock Agent + Knowledge Base
   - Test via AWS CLI
   - No authentication required
   - Simpler setup
   - Lower cost

2. **Full stack**: Backend + API Gateway + Cognito + React frontend
   - Test via browser
   - User authentication with Cognito
   - Production-ready architecture
   - Slightly higher cost

## Configuration

### Enable/Disable Frontend

Edit `terraform/terraform.tfvars`:

```hcl
# Backend-only mode (default)
enable_frontend = false

# Full stack mode
enable_frontend = true
```

## Backend-Only Mode (enable_frontend = false)

### What Gets Deployed
- ✅ Lambda functions (direct and agent)
- ✅ Bedrock Agent with Action Groups
- ✅ Knowledge Base with OpenSearch
- ✅ S3 bucket for knowledge base data
- ❌ API Gateway (not deployed)
- ❌ Cognito User Pool (not deployed)

### Testing
Use AWS CLI to invoke Lambda functions directly:

```bash
# Test direct Lambda
aws lambda invoke \
  --function-name dev-bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Tokyo"}' \
  response.json && cat response.json | jq

# Test agent Lambda
aws lambda invoke \
  --function-name dev-bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Paris"}' \
  response.json && cat response.json | jq
```

Or use the test script:
```bash
./scripts/test-lambda.sh both Geneva
```

### When to Use
- Learning Bedrock and agents
- Backend development and testing
- Cost-conscious POC
- No need for browser access
- Simple CLI-based workflows

### Monthly Cost Estimate
- Lambda: ~$0 (free tier covers most testing)
- Bedrock: Pay per request (~$0.001 per request)
- OpenSearch: ~$175/month (1 OCU)
- **Total: ~$175/month**

## Full Stack Mode (enable_frontend = true)

### What Gets Deployed
- ✅ Lambda functions (direct and agent)
- ✅ Bedrock Agent with Action Groups
- ✅ Knowledge Base with OpenSearch
- ✅ S3 bucket for knowledge base data
- ✅ API Gateway with REST API
- ✅ Cognito User Pool with authentication
- ✅ Rate limiting (25 req/sec)
- ✅ CORS configuration

### Testing
1. **Via React App** (recommended):
   ```bash
   cd frontend
   npm install
   npm start
   ```
   Open `http://localhost:3000`, sign in, and test via UI

2. **Via curl** (with authentication):
   ```bash
   # Get JWT token from Cognito (sign in via React app first)
   curl -X POST https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/direct \
     -H "Content-Type: application/json" \
     -H "Authorization: <JWT_TOKEN>" \
     -d '{"city": "Tokyo"}'
   ```

### When to Use
- Building a production application
- Need browser-based access
- Demonstrating to non-technical users
- Require user authentication
- Want to explore full AWS integration

### Monthly Cost Estimate
- Lambda: ~$0 (free tier)
- Bedrock: Pay per request (~$0.001 per request)
- OpenSearch: ~$175/month (1 OCU)
- API Gateway: ~$3.50 per million requests
- Cognito: Free for first 50,000 MAUs
- **Total: ~$175-180/month** (assuming light usage)

## Switching Between Modes

### From Backend-Only to Full Stack

1. Edit `terraform/terraform.tfvars`:
   ```hcl
   enable_frontend = true
   ```

2. Apply changes:
   ```bash
   cd terraform
   terraform apply
   ```

3. Get Cognito configuration:
   ```bash
   terraform output cognito_user_pool_id
   terraform output cognito_client_id
   ```

4. Update React app config if needed (should be automatic)

5. Start React app:
   ```bash
   cd ../frontend
   npm install
   npm start
   ```

### From Full Stack to Backend-Only

1. Edit `terraform/terraform.tfvars`:
   ```hcl
   enable_frontend = false
   ```

2. Apply changes:
   ```bash
   cd terraform
   terraform apply
   ```

This will destroy:
- API Gateway
- Cognito User Pool (users will be deleted!)
- All authentication configuration

Lambda functions remain unchanged and can still be tested via AWS CLI.

**Note on Deletion Protection**: The Cognito User Pool is configured with `deletion_protection = "INACTIVE"` for test/dev environments, allowing Terraform to destroy it cleanly. For production deployments, you should change this to `"ACTIVE"` in `terraform/cognito.tf` to prevent accidental deletion of user data.

## Architecture Diagrams

### Backend-Only Architecture
```
AWS CLI → Lambda Functions → Bedrock Agent → Knowledge Base
                                    ↓
                              Claude 3 Haiku
```

### Full Stack Architecture
```
Browser → React App → Cognito (Auth) → API Gateway → Lambda Functions → Bedrock Agent → Knowledge Base
                           ↓                                                    ↓
                       JWT Token                                          Claude 3 Haiku
```

## Security Considerations

### Backend-Only Mode
- Lambda functions are not publicly accessible
- Requires AWS credentials to invoke
- No authentication layer needed
- Good for development/testing

### Full Stack Mode
- API Gateway is publicly accessible
- Cognito provides user authentication
- JWT tokens required for all requests
- Rate limiting prevents abuse
- Production-ready security

## Troubleshooting

### "Not deployed" in Terraform outputs

If you see outputs like:
```
api_gateway_url = "Not deployed - set enable_frontend = true to deploy"
```

This means `enable_frontend = false` and those resources weren't created. This is expected behavior.

### Frontend can't connect to API

1. Verify `enable_frontend = true` in terraform.tfvars
2. Check API Gateway was deployed: `terraform output api_gateway_url`
3. Verify Cognito is configured: `terraform output cognito_user_pool_id`
4. Check React app config in `frontend/src/aws-config.js`

### Lambda functions work via CLI but not via API Gateway

1. Verify API Gateway is deployed: `enable_frontend = true`
2. Check you're signed in to the React app
3. Verify JWT token is being sent in Authorization header
4. Check CloudWatch logs for Lambda errors

## Best Practices

### For Learning/Development
- Start with `enable_frontend = false`
- Test backend via AWS CLI
- Enable frontend when ready to build UI

### For Production
- Use `enable_frontend = true`
- Configure custom domain for API Gateway
- Enable MFA in Cognito
- Set up CloudWatch alarms
- Use separate environments (dev/staging/prod)

### For Cost Optimization
- Use `enable_frontend = false` when not actively testing UI
- Consider disabling knowledge base if not needed: `enable_knowledge_base = false`
- Tear down entire stack when not in use: `terraform destroy`

## Related Documentation

- [Frontend README](../frontend/README.md) - React app setup and usage
- [Authentication Guide](./AUTHENTICATION.md) - Cognito configuration details
- [Deployment Guide](./DEPLOYMENT.md) - General deployment instructions
- [API Documentation](./API.md) - API Gateway endpoints and usage
