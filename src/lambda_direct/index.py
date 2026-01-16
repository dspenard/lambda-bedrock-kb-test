import json
import boto3
from botocore.exceptions import ClientError

# Initialize Bedrock client
bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')

# Model ID for Claude 3 Haiku (supports ON_DEMAND)
MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"

def get_city_from_event(event):
    """
    Extract city name from the Lambda event.
    Supports multiple input formats including Bedrock agent format.
    """
    city_name = None
    
    # Check if it's a Bedrock agent call
    if 'requestBody' in event and 'content' in event['requestBody']:
        try:
            content = event['requestBody']['content']
            if 'application/json' in content:
                properties = content['application/json'].get('properties', [])
                for prop in properties:
                    if prop.get('name') == 'city':
                        city_name = prop.get('value')
                        break
        except (KeyError, TypeError):
            pass
    
    # Check if it's from API Gateway
    if not city_name and 'body' in event:
        try:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
            city_name = body.get('city')
        except (json.JSONDecodeError, AttributeError):
            pass
    
    # Check if it's direct invocation with city parameter
    if not city_name and 'city' in event:
        city_name = event['city']
    
    # Check query string parameters (for API Gateway)
    if not city_name and 'queryStringParameters' in event and event['queryStringParameters']:
        city_name = event['queryStringParameters'].get('city')
    
    # For agent calls, also check the inputText
    if not city_name and 'inputText' in event:
        # Extract city name from natural language input
        input_text = event['inputText']
        # Simple extraction - look for common patterns
        words = input_text.split()
        for i, word in enumerate(words):
            if word.lower() in ['about', 'for', 'in'] and i + 1 < len(words):
                city_name = words[i + 1]
                break
        # If no pattern found, use the whole input as potential city name
        if not city_name:
            city_name = input_text.strip()
    
    return city_name

def invoke_claude(prompt):
    """
    Invoke Claude 3 Haiku via Bedrock
    """
    try:
        # Prepare the request body for Claude
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        }
        
        # Invoke the model
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(body),
            contentType='application/json'
        )
        
        # Parse the response
        response_body = json.loads(response['body'].read())
        return response_body['content'][0]['text']
        
    except ClientError as e:
        print(f"Error invoking Bedrock: {e}")
        raise e

def handler(event, context):
    """
    Lambda function handler that uses Claude 3 Haiku to generate city facts.
    Accepts any city name as input and generates facts using the model.
    Handles both direct invocation and Bedrock agent invocation.
    """
    try:
        # Log the incoming event for debugging
        print(f"Received event: {json.dumps(event)}")
        
        # Check if this is a Bedrock agent invocation
        is_agent_call = False
        if 'agent' in event or 'sessionId' in event or 'inputText' in event or 'messageVersion' in event:
            is_agent_call = True
            print(f"Detected agent call: {is_agent_call}")
        
        # Extract city name from event
        city_name = get_city_from_event(event)
        
        # For agent calls, also check the inputText
        if not city_name and is_agent_call:
            if 'inputText' in event:
                # Use the input text directly as the city name if no specific city was extracted
                city_name = event['inputText'].strip()
            elif 'messageVersion' in event and 'inputText' in event:
                city_name = event['inputText'].strip()
        
        # Validate input - only check if city name is provided
        if not city_name or not city_name.strip():
            error_response = {
                "error": "Missing city parameter",
                "message": "Please provide a city name in the request",
                "example_usage": {
                    "direct_invocation": {"city": "Tokyo"},
                    "api_gateway_body": {"body": "{\"city\": \"Tokyo\"}"},
                    "api_gateway_query": "?city=Tokyo"
                }
            }
            
            if is_agent_call:
                # For agent calls, return a simpler format
                return {
                    "messageVersion": "1.0",
                    "response": {
                        "actionGroup": event.get("actionGroup", "CityFactsActionGroup"),
                        "apiPath": event.get("apiPath", "/city-facts"),
                        "httpMethod": event.get("httpMethod", "POST"),
                        "httpStatusCode": 400,
                        "responseBody": {
                            "application/json": {
                                "body": json.dumps(error_response)
                            }
                        }
                    }
                }
            else:
                return {
                    "statusCode": 400,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Headers": "Content-Type",
                        "Access-Control-Allow-Methods": "POST,OPTIONS"
                    },
                    "body": json.dumps(error_response)
                }
        
        # Normalize city name for consistent output
        normalized_city = city_name.strip().title()
        
        # Create prompt for Claude
        prompt = f"""Please provide exactly 10 interesting and factual information points about {normalized_city}. 
        Format your response as a JSON object with the following structure:
        {{
            "city": "{normalized_city}",
            "facts": [
                "fact 1",
                "fact 2",
                ...
            ]
        }}
        
        Make sure each fact is unique, interesting, and accurate. Include a mix of historical, cultural, geographical, and modern facts about the city. If this is not a real city or you don't have information about it, please indicate that in your response."""
        
        # Get response from Claude
        claude_response = invoke_claude(prompt)
        
        # Try to parse Claude's JSON response
        try:
            # First try to parse the response directly
            city_data = json.loads(claude_response)
            facts = city_data.get("facts", [])
        except json.JSONDecodeError:
            # If that fails, try to extract JSON from the response
            try:
                # Look for JSON-like content in the response
                start_idx = claude_response.find('{')
                end_idx = claude_response.rfind('}') + 1
                if start_idx != -1 and end_idx > start_idx:
                    json_str = claude_response[start_idx:end_idx]
                    city_data = json.loads(json_str)
                    facts = city_data.get("facts", [])
                else:
                    raise ValueError("No JSON found")
            except (json.JSONDecodeError, ValueError):
                # Final fallback - extract numbered facts from text
                facts = []
                lines = claude_response.split('\n')
                for line in lines:
                    line = line.strip()
                    # Skip empty lines, JSON formatting characters, and very short lines
                    if not line or len(line) <= 3:
                        continue
                    # Skip all JSON syntax characters and patterns
                    if line in ['{', '}', '[', ']', ',', '",', '"', '":"', '"facts":', '"city":']:
                        continue
                    # Skip lines that look like JSON structure
                    if line.startswith('{') or line.endswith('}') or line.startswith('[') or line.endswith(']'):
                        continue
                    if line.endswith(':') or line.endswith('": [') or line.endswith('",') or line.endswith('"'):
                        continue
                    # Skip lines that are just field names
                    if line.startswith('"') and '":' in line:
                        continue
                    # Remove leading numbers, bullets, quotes, and commas
                    cleaned = line.lstrip('0123456789.-) ').strip('"').strip(',').strip()
                    # Additional cleanup - remove any remaining quotes or brackets
                    cleaned = cleaned.replace('{', '').replace('}', '').replace('[', '').replace(']', '').strip()
                    # Only add substantial content (more than 20 chars, contains letters)
                    if cleaned and len(cleaned) > 20 and any(c.isalpha() for c in cleaned):
                        facts.append(cleaned)
                # Limit to 10 facts
                facts = facts[:10]
        
        success_response = {
            "city": normalized_city,
            "facts": facts,
            "total_facts": len(facts),
            "message": f"Here are facts about {normalized_city} generated by Claude 3 Haiku!",
            "model_used": MODEL_ID,
            "requested_city": city_name
        }
        
        if is_agent_call:
            # For agent calls, return the expected format
            return {
                "messageVersion": "1.0",
                "response": {
                    "actionGroup": event.get("actionGroup", "CityFactsActionGroup"),
                    "apiPath": event.get("apiPath", "/city-facts"),
                    "httpMethod": event.get("httpMethod", "POST"),
                    "httpStatusCode": 200,
                    "responseBody": {
                        "application/json": {
                            "body": json.dumps(success_response)
                        }
                    }
                }
            }
        else:
            # For direct calls, return HTTP response format
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Allow-Methods": "POST,OPTIONS"
                },
                "body": json.dumps(success_response)
            }
        
    except Exception as e:
        print(f"Error in handler: {str(e)}")
        error_response = {
            "error": "Internal server error",
            "message": str(e),
            "requested_city": city_name if 'city_name' in locals() else "Unknown"
        }
        
        if is_agent_call:
            return {
                "messageVersion": "1.0",
                "response": {
                    "actionGroup": event.get("actionGroup", "CityFactsActionGroup"),
                    "apiPath": event.get("apiPath", "/city-facts"),
                    "httpMethod": event.get("httpMethod", "POST"),
                    "httpStatusCode": 500,
                    "responseBody": {
                        "application/json": {
                            "body": json.dumps(error_response)
                        }
                    }
                }
            }
        else:
            return {
                "statusCode": 500,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Allow-Methods": "POST,OPTIONS"
                },
                "body": json.dumps(error_response)
            }