# API Documentation

This document provides comprehensive API documentation for the Bedrock Agent Test Bed, including OpenAPI specifications, request/response examples, and usage patterns.

## Table of Contents

- [Overview](#overview)
- [Lambda Functions](#lambda-functions)
- [OpenAPI Specifications](#openapi-specifications)
- [Request/Response Examples](#requestresponse-examples)
- [Error Handling](#error-handling)

---

## Overview

The Bedrock Agent Test Bed exposes two Lambda functions that can be invoked directly or through AWS services:

1. **Lambda Direct** (`lambda_direct`) - Direct model access via Bedrock Runtime API
2. **Lambda Agent** (`lambda_agent`) - Agent-based orchestration via Bedrock Agent API

Both functions accept a simple city name input and return comprehensive city information.

### Important: The `/city-facts` API

The `/city-facts` API is an **internal action group API** used by the Bedrock Agent. It is **not called directly by users**. Here's how it works:

- **Defined in**: OpenAPI specification within the agent configuration (`bedrock_agent.tf`)
- **Called by**: The Bedrock Agent (automatically, based on the prompt)
- **Executor**: `lambda_direct` function
- **Purpose**: Provides the agent with a tool to get general city facts

**User Flow**:
```
User → lambda_agent → Bedrock Agent → (internally calls /city-facts) → lambda_direct
                            ↓
                    (also searches knowledge base)
                            ↓
                    (synthesizes all data)
                            ↓
                        Response
```

**You do NOT call `/city-facts` directly**. Instead, you invoke `lambda_agent`, which invokes the Bedrock Agent, which then decides to use the `/city-facts` action group as one of its tools.

---

## Architecture: How the APIs Work Together

### Direct Model Access Flow
```
User
  ↓
  └─→ aws lambda invoke --function-name lambda_direct --payload '{"city":"Tokyo"}'
        ↓
        └─→ lambda_direct function
              ↓
              └─→ bedrock-runtime.invoke_model() [Claude 3.5 Haiku]
                    ↓
                    └─→ Response (model training data only)
```

### Agent-Based Flow
```
User
  ↓
  └─→ aws lambda invoke --function-name lambda_agent --payload '{"city":"Geneva"}'
        ↓
        └─→ lambda_agent function
              ↓
              └─→ bedrock-agent-runtime.invoke_agent()
                    ↓
                    └─→ Bedrock Agent (orchestrator)
                          ↓
                          ├─→ Knowledge Base Search
                          │     ↓
                          │     └─→ OpenSearch Serverless (vector search)
                          │           ↓
                          │           └─→ Returns: air quality, water pollution, cost of living
                          │
                          └─→ Action Group: POST /city-facts (internal API)
                                ↓
                                └─→ lambda_direct function
                                      ↓
                                      └─→ bedrock-runtime.invoke_model()
                                            ↓
                                            └─→ Returns: general city facts
                          ↓
                          └─→ Agent synthesizes all data
                                ↓
                                └─→ Response (KB data + general facts)
```

### Key Architectural Points

1. **Two User-Facing Lambda Functions**:
   - `lambda_direct` - Can be called directly by users
   - `lambda_agent` - Can be called directly by users

2. **One Internal API**:
   - `POST /city-facts` - Only called by the Bedrock Agent, not by users
   - Defined in OpenAPI spec in agent configuration
   - Executor is `lambda_direct` function

3. **Knowledge Base Association**:
   - Knowledge base is associated with the agent via Terraform
   - Agent automatically has access to search the knowledge base
   - `lambda_direct` does NOT have direct access to the knowledge base
   - Only the agent can retrieve from the knowledge base

4. **Why `lambda_direct` Doesn't Use Knowledge Base**:
   - It calls `invoke_model()` directly - just the model, no orchestration
   - No agent involved = no knowledge base access
   - No automatic tool selection or data synthesis

5. **Why Agent Uses Knowledge Base**:
   - Calls `invoke_agent()` - invokes the orchestration service
   - Agent has knowledge base associated with it
   - Agent has IAM permissions to call `bedrock:Retrieve`
   - Agent automatically decides when to search knowledge base based on prompt

---

## Lambda Functions

### 1. Lambda Direct (Direct Model Access)

**Function Name**: `{prefix}-bedrock-agent-testbed-city-facts-direct`

**Purpose**: Directly invokes Claude 3.5 Haiku foundation model to generate city facts

**Invocation Methods**:
- **Direct Lambda invocation** - Called by users via AWS Lambda API
- **Bedrock Agent Action Group** - Called internally by the agent via `/city-facts` API (not user-facing)

**When Called Directly**:
- Uses `bedrock-runtime.invoke_model()` API
- Returns facts based on model's training data only
- No knowledge base access

**When Called by Agent** (via `/city-facts` action group):
- Still uses `bedrock-runtime.invoke_model()` API
- Returns facts based on model's training data only
- Agent combines this with knowledge base data separately

**Input Format**:
```json
{
  "city": "Tokyo"
}
```

**Output Format**:
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{...}"
}
```

---

### 2. Lambda Agent (Agent-Based Orchestration)

**Function Name**: `{prefix}-bedrock-agent-testbed-city-facts-agent`

**Purpose**: Invokes Bedrock Agent which orchestrates knowledge base searches and action group calls

**Invocation Methods**:
- **Direct Lambda invocation** - Called by users via AWS Lambda API

**How It Works**:
1. Receives city name from user
2. Calls `bedrock-agent-runtime.invoke_agent()` API
3. Agent automatically orchestrates:
   - **Knowledge Base Search**: Queries OpenSearch for city data (air quality, water pollution, cost of living)
     - Knowledge base is associated with the agent via Terraform
     - Agent has `bedrock:Retrieve` IAM permission
   - **Action Group Call**: Internally calls `POST /city-facts` API
     - This invokes `lambda_direct` function
     - Returns general city facts from the model
4. Agent synthesizes all data sources into a coherent response

**Key Point**: The agent decides which tools to use based on the prompt. The `/city-facts` API is one of the tools available to the agent, but users never call it directly.

**Input Format**:
```json
{
  "city": "Geneva"
}
```

**Output Format**:
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{...}"
}
```

---

## OpenAPI Specifications

### City Facts Action Group API (Internal - Agent Use Only)

This OpenAPI specification defines the API contract for the Bedrock Agent's action group that invokes the `lambda_direct` function.

**IMPORTANT**: This API is **not called directly by users**. It is an internal tool definition that tells the Bedrock Agent how to invoke `lambda_direct` as an action group.

**How It's Used**:
1. Defined in `terraform/bedrock_agent.tf` as part of the agent configuration
2. The Bedrock Agent reads this OpenAPI spec to understand available tools
3. When the agent decides it needs city facts, it internally calls `POST /city-facts`
4. This triggers the execution of `lambda_direct` function
5. The response is returned to the agent, which combines it with other data sources

**User Interaction**:
- ❌ Users do NOT call `POST /city-facts` directly
- ✅ Users call `lambda_agent` function
- ✅ Agent internally uses `/city-facts` as a tool

```yaml
openapi: 3.0.0
info:
  title: City Facts API
  version: 1.0.0
  description: API for getting interesting facts about cities

paths:
  /city-facts:
    post:
      summary: Get facts about a city
      description: Returns 10 interesting facts about the specified city
      operationId: getCityFacts
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                city:
                  type: string
                  description: The name of the city to get facts about
                  example: "Tokyo"
              required:
                - city
      responses:
        '200':
          description: Successful response with city facts
          content:
            application/json:
              schema:
                type: object
                properties:
                  city:
                    type: string
                    description: The city name
                    example: "Tokyo"
                  facts:
                    type: array
                    items:
                      type: string
                    description: List of interesting facts about the city
                    example:
                      - "Tokyo is the most populous metropolitan area in the world"
                      - "The city was originally known as Edo"
                  total_facts:
                    type: integer
                    description: Number of facts returned
                    example: 10
                  message:
                    type: string
                    description: Success message
                  model_used:
                    type: string
                    description: The Bedrock model used
                  requested_city:
                    type: string
                    description: The original city name from request
        '400':
          description: Bad request - missing or invalid city parameter
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                  message:
                    type: string
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                  message:
                    type: string
                  requested_city:
                    type: string
```

---

## Request/Response Examples

### Example 1: Direct Lambda Invocation (lambda_direct)

#### Request
```bash
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Tokyo"}' \
  response.json
```

#### Response (response.json)
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"city\": \"Tokyo\", \"facts\": [\"Tokyo is the most populous metropolitan area in the world, with over 37 million residents.\", \"The city was originally known as Edo and served as the seat of power for the Tokugawa shogunate from the early 17th to mid-19th century.\", \"The Tokyo Imperial Palace, the current residence of the Emperor of Japan, is located in the heart of the city.\", \"Tokyo is home to the world-famous Tsukiji Fish Market, which is the largest wholesale fish and seafood market in the world.\", \"The Tokyo Metro system is the busiest and one of the most extensive subway networks in the world, with over 9 million daily riders.\", \"The city is renowned for its vibrant and diverse culinary scene, offering a wide range of traditional Japanese cuisine as well as international flavors.\", \"Tokyo is also known for its unique blend of modern and traditional architecture, with iconic landmarks like the Tokyo Skytree and the Sensoji Temple.\", \"Tokyo is a global leader in technology and innovation, hosting the headquarters of numerous multinational corporations and tech companies.\", \"The city is home to the oldest and most prestigious universities in Japan, such as the University of Tokyo, which has produced numerous Nobel Prize laureates.\", \"Tokyo is also a major global financial hub, ranking as one of the world's most important centers for banking, finance, and trade.\"], \"total_facts\": 10, \"message\": \"Here are facts about Tokyo generated by Claude 3.5 Haiku!\", \"model_used\": \"anthropic.claude-3-haiku-20240307-v1:0\", \"requested_city\": \"Tokyo\"}"
}
```

#### Parsed Response Body
```json
{
  "city": "Tokyo",
  "facts": [
    "Tokyo is the most populous metropolitan area in the world, with over 37 million residents.",
    "The city was originally known as Edo and served as the seat of power for the Tokugawa shogunate from the early 17th to mid-19th century.",
    "The Tokyo Imperial Palace, the current residence of the Emperor of Japan, is located in the heart of the city.",
    "Tokyo is home to the world-famous Tsukiji Fish Market, which is the largest wholesale fish and seafood market in the world.",
    "The Tokyo Metro system is the busiest and one of the most extensive subway networks in the world, with over 9 million daily riders.",
    "The city is renowned for its vibrant and diverse culinary scene, offering a wide range of traditional Japanese cuisine as well as international flavors.",
    "Tokyo is also known for its unique blend of modern and traditional architecture, with iconic landmarks like the Tokyo Skytree and the Sensoji Temple.",
    "Tokyo is a global leader in technology and innovation, hosting the headquarters of numerous multinational corporations and tech companies.",
    "The city is home to the oldest and most prestigious universities in Japan, such as the University of Tokyo, which has produced numerous Nobel Prize laureates.",
    "Tokyo is also a major global financial hub, ranking as one of the world's most important centers for banking, finance, and trade."
  ],
  "total_facts": 10,
  "message": "Here are facts about Tokyo generated by Claude 3.5 Haiku!",
  "model_used": "anthropic.claude-3-haiku-20240307-v1:0",
  "requested_city": "Tokyo"
}
```

---

### Example 2: Agent Lambda Invocation (lambda_agent)

#### Request
```bash
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city": "Geneva"}' \
  response.json
```

#### Response (response.json)
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"city\": \"Geneva\", \"agent_response\": \"Here is what I can share about Geneva:\\n\\nBased on the search results, Geneva has an air quality index of 20.17 and a water pollution index of 22.92. The cost of living index for Geneva is 131.97, with a rent index of 66.41, a cost of living plus rent index of 101.16, a groceries index of 133.98, a restaurant price index of 130.09, and a local purchasing power index of 145.37.\\n\\nGeneva is the second-most populous city in Switzerland and is known as the \\\"Peace Capital\\\" due to the presence of numerous international organizations, including the United Nations Office at Geneva and the International Committee of the Red Cross. The city is situated on the shores of Lake Geneva and is surrounded by the Alps and Jura mountains, offering stunning natural scenery.\\n\\nGeneva is a global center for diplomacy and banking, and is home to the headquarters of many international organizations. The city has a rich cultural heritage, with numerous museums, art galleries, and historic landmarks, including the iconic Jet d'Eau fountain. Geneva is also renowned for its high quality of life, excellent public transportation, and vibrant culinary scene.\", \"message\": \"City facts for Geneva generated via Bedrock Agent\", \"agent_id\": \"137GJDIGTS\", \"session_id\": \"unique-session-id\", \"requested_city\": \"Geneva\", \"source\": \"bedrock_agent\"}"
}
```

#### Parsed Response Body
```json
{
  "city": "Geneva",
  "agent_response": "Here is what I can share about Geneva:\n\nBased on the search results, Geneva has an air quality index of 20.17 and a water pollution index of 22.92. The cost of living index for Geneva is 131.97, with a rent index of 66.41, a cost of living plus rent index of 101.16, a groceries index of 133.98, a restaurant price index of 130.09, and a local purchasing power index of 145.37.\n\nGeneva is the second-most populous city in Switzerland and is known as the \"Peace Capital\" due to the presence of numerous international organizations, including the United Nations Office at Geneva and the International Committee of the Red Cross. The city is situated on the shores of Lake Geneva and is surrounded by the Alps and Jura mountains, offering stunning natural scenery.\n\nGeneva is a global center for diplomacy and banking, and is home to the headquarters of many international organizations. The city has a rich cultural heritage, with numerous museums, art galleries, and historic landmarks, including the iconic Jet d'Eau fountain. Geneva is also renowned for its high quality of life, excellent public transportation, and vibrant culinary scene.",
  "message": "City facts for Geneva generated via Bedrock Agent",
  "agent_id": "137GJDIGTS",
  "session_id": "unique-session-id",
  "requested_city": "Geneva",
  "source": "bedrock_agent"
}
```

**Key Differences in Agent Response**:
- Includes **knowledge base data**: Air quality index (20.17), water pollution index (22.92), cost of living metrics
- Combines **multiple sources**: Knowledge base + action group (general facts)
- More **comprehensive information**: Real-world data + general knowledge

---

### Example 3: Error Response - Missing City Parameter

#### Request
```bash
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload '{}' \
  response.json
```

#### Response
```json
{
  "statusCode": 400,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"error\": \"Missing city parameter\", \"message\": \"Please provide a city name in the request\", \"example_usage\": {\"direct_invocation\": {\"city\": \"Tokyo\"}, \"api_gateway_body\": {\"body\": \"{\\\"city\\\": \\\"Tokyo\\\"}\"}, \"api_gateway_query\": \"?city=Tokyo\"}}"
}
```

---

### Example 4: Testing with Helper Scripts

#### Using test-lambda.sh
```bash
# Test direct Lambda
./scripts/test-lambda.sh direct Tokyo

# Test agent Lambda
./scripts/test-lambda.sh agent Geneva

# Test both approaches
./scripts/test-lambda.sh both Berlin
```

#### Using dev-workflow.sh
```bash
# Test with recommended cities
./scripts/dev-workflow.sh test Geneva
./scripts/dev-workflow.sh test-agent "New York City"
```

---

## Error Handling

### Error Response Format

All error responses follow this structure:

```json
{
  "statusCode": 400 | 500,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"error\": \"Error type\", \"message\": \"Detailed error message\", \"requested_city\": \"CityName\"}"
}
```

### Common Error Codes

| Status Code | Error Type | Description | Solution |
|-------------|-----------|-------------|----------|
| 400 | Missing city parameter | No city name provided in request | Include `{"city": "CityName"}` in payload |
| 500 | Internal server error | Bedrock API error or Lambda execution error | Check CloudWatch logs for details |
| 500 | Configuration error | Missing environment variables | Verify Lambda configuration |
| 500 | Access denied | IAM permissions issue | Check agent role has `bedrock:Retrieve` permission |

### Debugging Tips

1. **Check CloudWatch Logs**:
   ```bash
   # View direct Lambda logs
   ./scripts/dev-workflow.sh logs-direct
   
   # View agent Lambda logs
   ./scripts/dev-workflow.sh logs-agent
   ```

2. **Verify Function Names**:
   ```bash
   # List Lambda functions with your prefix
   aws lambda list-functions --query 'Functions[?contains(FunctionName, `bedrock-agent-testbed`)].FunctionName'
   ```

3. **Test with Known Cities**:
   - Cities with knowledge base data: Geneva, Berlin, Tokyo, London, Paris
   - Cities without KB data: Any city (will return general facts only)

---

## API Usage Patterns

### Pattern 1: Direct Testing (No Agent)

Use `lambda_direct` for:
- Baseline Bedrock model testing
- Simple fact generation
- Performance benchmarking
- Cost comparison

```bash
aws lambda invoke \
  --function-name {prefix}-bedrock-agent-testbed-city-facts-direct \
  --payload '{"city": "Paris"}' \
  response.json
```

### Pattern 2: Agent-Based Testing (Full Capabilities)

Use `lambda_agent` for:
- Knowledge base integration testing
- Action group orchestration
- Multi-source data synthesis
- Complex query handling

```bash
aws lambda invoke \
  --function-name {prefix}-bedrock-agent-testbed-city-facts-agent \
  --payload '{"city": "Geneva"}' \
  response.json
```

### Pattern 3: Comparison Testing

Test both approaches with the same city to compare:
- Response quality
- Data richness
- Execution time
- Cost per invocation

```bash
./scripts/test-lambda.sh both Geneva
```

---

## Integration Examples

### Python Integration

```python
import boto3
import json

lambda_client = boto3.client('lambda', region_name='us-east-1')

def get_city_facts_direct(city_name):
    """Get city facts using direct model access"""
    response = lambda_client.invoke(
        FunctionName='bedrock-agent-testbed-city-facts-direct',
        InvocationType='RequestResponse',
        Payload=json.dumps({'city': city_name})
    )
    
    result = json.loads(response['Payload'].read())
    body = json.loads(result['body'])
    return body['facts']

def get_city_facts_agent(city_name):
    """Get city facts using Bedrock agent"""
    response = lambda_client.invoke(
        FunctionName='bedrock-agent-testbed-city-facts-agent',
        InvocationType='RequestResponse',
        Payload=json.dumps({'city': city_name})
    )
    
    result = json.loads(response['Payload'].read())
    body = json.loads(result['body'])
    return body['agent_response']

# Usage
facts = get_city_facts_direct('Tokyo')
agent_response = get_city_facts_agent('Geneva')
```

### Node.js Integration

```javascript
const AWS = require('aws-sdk');
const lambda = new AWS.Lambda({ region: 'us-east-1' });

async function getCityFactsDirect(cityName) {
  const params = {
    FunctionName: 'bedrock-agent-testbed-city-facts-direct',
    InvocationType: 'RequestResponse',
    Payload: JSON.stringify({ city: cityName })
  };
  
  const response = await lambda.invoke(params).promise();
  const result = JSON.parse(response.Payload);
  const body = JSON.parse(result.body);
  return body.facts;
}

async function getCityFactsAgent(cityName) {
  const params = {
    FunctionName: 'bedrock-agent-testbed-city-facts-agent',
    InvocationType: 'RequestResponse',
    Payload: JSON.stringify({ city: cityName })
  };
  
  const response = await lambda.invoke(params).promise();
  const result = JSON.parse(response.Payload);
  const body = JSON.parse(result.body);
  return body.agent_response;
}

// Usage
const facts = await getCityFactsDirect('Tokyo');
const agentResponse = await getCityFactsAgent('Geneva');
```

---

## Rate Limits and Quotas

### AWS Lambda Limits
- **Concurrent executions**: 1000 (default account limit)
- **Function timeout**: 900 seconds (configured to lower values)
- **Payload size**: 6 MB (synchronous), 256 KB (asynchronous)

### Bedrock Limits
- **Model invocations**: Varies by model and region
- **Knowledge base queries**: Subject to OpenSearch Serverless limits
- **Agent invocations**: Subject to Bedrock agent quotas

### Best Practices
1. Implement exponential backoff for retries
2. Monitor CloudWatch metrics for throttling
3. Use asynchronous invocation for non-critical requests
4. Cache responses when appropriate

---

## Frequently Asked Questions

### Q: Can I call the `/city-facts` API directly?

**A**: No. The `/city-facts` API is an internal action group API that only the Bedrock Agent can call. It's defined in the agent's OpenAPI specification and is not exposed as a public endpoint.

To get city facts, you have two options:
1. Call `lambda_direct` directly for model-only facts
2. Call `lambda_agent` for agent-orchestrated facts (which internally uses `/city-facts`)

### Q: Why does `lambda_direct` not use the knowledge base when called directly, but does when called by the agent?

**A**: This is a common misconception. `lambda_direct` **never** accesses the knowledge base, even when called by the agent. Here's what actually happens:

- **When called directly**: `lambda_direct` → `invoke_model()` → returns facts
- **When called by agent**: Agent searches knowledge base separately, then calls `lambda_direct` via `/city-facts`, then combines both results

The agent is the orchestrator that combines multiple data sources. `lambda_direct` always just calls the model.

### Q: How does the agent know to use the knowledge base?

**A**: Three things enable this:

1. **Association**: The knowledge base is associated with the agent via Terraform (`aws_bedrockagent_agent_knowledge_base_association`)
2. **Permissions**: The agent's IAM role has `bedrock:Retrieve` permission
3. **Prompt**: The prompt hints at needing specific data (e.g., "including air quality and cost of living")

The agent automatically decides when to search the knowledge base based on the prompt.

### Q: What APIs do I actually call as a user?

**A**: You call two Lambda functions:

1. **`lambda_direct`** - For simple, model-only responses
   ```bash
   aws lambda invoke --function-name lambda_direct --payload '{"city":"Tokyo"}' response.json
   ```

2. **`lambda_agent`** - For agent-orchestrated responses with knowledge base
   ```bash
   aws lambda invoke --function-name lambda_agent --payload '{"city":"Geneva"}' response.json
   ```

You never call `/city-facts` directly - it's an internal API used by the agent.

### Q: How do I add more action groups?

**A**: To add more action groups:

1. Create a new Lambda function (or reuse existing)
2. Define a new OpenAPI specification in `bedrock_agent.tf`
3. Add it as an action group to the agent
4. The agent will automatically have access to this new tool

Example action groups you might add:
- Weather data lookup
- Restaurant recommendations
- Hotel availability
- Transportation options

---

## Additional Resources

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Project README](../README.md)
- [Troubleshooting Guide](../README.md#-troubleshooting)
