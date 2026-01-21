# Authentication Guide

This project uses AWS Cognito for user authentication and authorization.

## Overview

- **User Pool**: Manages user accounts, passwords, and email verification
- **API Gateway Authorizer**: Validates JWT tokens from Cognito
- **React App**: Uses AWS Amplify for authentication UI and token management

## Architecture

```
User → React App → Cognito (Login) → JWT Token → API Gateway → Lambda
                                         ↓
                                    Validates Token
```

## Configuration

### Cognito User Pool Settings

- **Sign-in method**: Email
- **Password requirements**:
  - Minimum 8 characters
  - Requires uppercase letter
  - Requires lowercase letter
  - Requires number
  - No special characters required
- **Email verification**: Required
- **Token validity**:
  - Access token: 1 hour
  - ID token: 1 hour
  - Refresh token: 30 days

### API Gateway Integration

- **Authorization type**: COGNITO_USER_POOLS
- **Token location**: `Authorization` header
- **Token caching**: 5 minutes (300 seconds)

## User Management

### Creating Users

**Option 1: Self-signup (Recommended)**
1. Open the React app at `http://localhost:3000`
2. Click "Create Account"
3. Enter email and password
4. Check email for verification code
5. Enter code to verify account

**Option 2: Admin-created user**
```bash
aws cognito-idp admin-create-user \
  --user-pool-id <USER_POOL_ID> \
  --username user@example.com \
  --user-attributes Name=email,Value=user@example.com Name=email_verified,Value=true \
  --temporary-password TempPass123! \
  --message-action SUPPRESS
```

### Viewing Users

```bash
aws cognito-idp list-users \
  --user-pool-id <USER_POOL_ID>
```

### Deleting Users

```bash
aws cognito-idp admin-delete-user \
  --user-pool-id <USER_POOL_ID> \
  --username user@example.com
```

## Testing Authentication

### Test Valid Request

```bash
# 1. Sign in and get token (use the React app or AWS CLI)
# 2. Make authenticated request
curl -X POST https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/direct \
  -H "Content-Type: application/json" \
  -H "Authorization: <JWT_TOKEN>" \
  -d '{"city": "Tokyo"}'
```

### Test Unauthorized Request

```bash
# Request without token should return 401
curl -X POST https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/direct \
  -H "Content-Type: application/json" \
  -d '{"city": "Tokyo"}'
```

Expected response:
```json
{"message":"Unauthorized"}
```

## Security Considerations

### Current Setup (Development)

✅ **Implemented:**
- User authentication with Cognito
- JWT token validation
- Rate limiting (25 req/sec)
- HTTPS only
- Password complexity requirements
- Email verification

⚠️ **Development-only settings:**
- Callback URLs include `localhost:3000`
- Deletion protection enabled (prevents accidental deletion)

### Production Recommendations

When deploying to production:

1. **Update callback URLs** in Cognito client:
   ```hcl
   callback_urls = ["https://yourdomain.com", "https://yourdomain.com/"]
   logout_urls   = ["https://yourdomain.com", "https://yourdomain.com/"]
   ```

2. **Enable MFA** (Multi-Factor Authentication):
   ```hcl
   mfa_configuration = "OPTIONAL"  # or "ON" for required
   ```

3. **Add custom domain** for Cognito hosted UI:
   ```hcl
   resource "aws_cognito_user_pool_domain" "custom" {
     domain          = "auth.yourdomain.com"
     certificate_arn = aws_acm_certificate.auth.arn
     user_pool_id    = aws_cognito_user_pool.city_facts_pool.id
   }
   ```

4. **Enable advanced security features**:
   - Compromised credentials check
   - Adaptive authentication
   - CloudWatch logging

5. **Set up CloudWatch alarms**:
   - Failed login attempts
   - Token validation failures
   - Unusual access patterns

## Troubleshooting

### "Unauthorized" error in React app

1. Check if user is signed in
2. Verify token is being sent in Authorization header
3. Check token hasn't expired (1 hour validity)
4. Try signing out and back in

### Email verification not received

1. Check spam folder
2. Verify email configuration in Cognito
3. Check CloudWatch logs for delivery issues
4. For testing, manually verify user:
   ```bash
   aws cognito-idp admin-update-user-attributes \
     --user-pool-id <USER_POOL_ID> \
     --username user@example.com \
     --user-attributes Name=email_verified,Value=true
   ```

### Password doesn't meet requirements

Password must have:
- At least 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number

Example valid password: `MyPass123`

## Cost Considerations

### Cognito Pricing (as of 2024)

- **Free tier**: 50,000 MAUs (Monthly Active Users)
- **After free tier**: $0.0055 per MAU

For this POC with a few test users, costs will be $0.

### API Gateway + Lambda Costs

Authentication doesn't add extra API Gateway costs, but each request still counts toward:
- API Gateway: $3.50 per million requests
- Lambda: $0.20 per million requests + compute time

## References

- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [AWS Amplify Authentication](https://docs.amplify.aws/react/build-a-backend/auth/)
- [API Gateway Cognito Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html)
