# Lambda Test Request Data

This directory contains sample JSON payloads for testing the Lambda functions.

## 🌟 Recommended Test Cities

For the best testing experience, use cities with complete knowledge base data:

**Cities with Both Air Quality AND Cost of Living Data:**
- Geneva, Zurich, Basel, Bern (Switzerland)
- Berlin, London, Paris, Madrid (Europe)
- Boston, Chicago, Los Angeles, Miami (USA)
- Beijing, Bangkok, Mumbai, Delhi (Asia)
- Montreal (Canada), Buenos Aires (Argentina)

**Why These Cities?** The agent can combine data from both knowledge base sources with general city facts, providing richer and more comprehensive responses.

## Test Files

### Direct Model Access Tests
- `direct-tokyo.json` - Test direct Lambda with Tokyo
- `direct-paris.json` - Test direct Lambda with Paris (has cost of living data)
- `direct-london.json` - Test direct Lambda with London (has both datasets)

### Agent-Based Tests  
- `agent-berlin.json` - Test agent Lambda with Berlin (has both datasets)
- `agent-sydney.json` - Test agent Lambda with Sydney

### Knowledge Base Specific Tests
- `test_agent_with_kb.json` - Test with Geneva (complete knowledge base data)
- `test_agent_kb_specific.json` - Test with Zurich (both datasets available)
- `test_agent_nyc.json` - Test with New York City (air quality data)

### Error Condition Tests
- `invalid-city.json` - Test with unsupported city (Atlantis)
- `missing-city.json` - Test with missing city parameter

## Usage

### Using AWS CLI
```bash
# Test direct model access with knowledge base city
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-direct \
  --cli-binary-format raw-in-base64-out \
  --payload file://data/lambda-tests/direct-london.json \
  response.json

# Test agent-based access with complete data city
aws lambda invoke \
  --function-name bedrock-agent-testbed-city-facts-agent \
  --cli-binary-format raw-in-base64-out \
  --payload file://data/lambda-tests/agent-berlin.json \
  response.json
```

### Using Development Scripts
```bash
# Test with cities that have complete knowledge base data
./test-lambda.sh direct Geneva
./test-lambda.sh agent Berlin
./test-lambda.sh both Zurich
```

## Expected Responses

### Successful Response (Direct)
```json
{
  "statusCode": 200,
  "headers": {"Content-Type": "application/json"},
  "body": "{\"city\": \"Geneva\", \"facts\": [...], \"total_facts\": 10, ...}"
}
```

### Successful Response (Agent with Knowledge Base)
```json
{
  "statusCode": 200,
  "headers": {"Content-Type": "application/json"},
  "body": "{\"city\": \"Berlin\", \"agent_response\": \"Berlin has an air quality index of 62.36 and cost of living index of...\", \"agent_id\": \"1DSXPQRXQJ\", ...}"
}
```

### Error Response (Invalid City)
```json
{
  "statusCode": 400,
  "headers": {"Content-Type": "application/json"},
  "body": "{\"error\": \"City not supported\", \"message\": \"...\", \"supported_cities\": [...]}"
}
```

## 📊 Knowledge Base Coverage

- **Air Quality & Water Pollution**: 500+ cities (2021 data)
- **Cost of Living**: 400+ cities (2018 data)  
- **Both Datasets**: 200+ cities with complete information

## Adding New Test Cases

To add new test cases:
1. Create a new JSON file with the desired payload
2. Follow the naming convention: `[type]-[city].json`
3. Use cities from the knowledge base for richer responses
4. Update this README with the new test case
5. Test the new payload with both Lambda functions if applicable