import json
import os
import boto3
from botocore.exceptions import ClientError

# Initialize Bedrock Agent Runtime client
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime', region_name='us-east-1')

def get_city_from_event(event):
    """
    Extract city name from the Lambda event.
    Supports multiple input formats.
    """
    city_name = None
    
    # Check if it's from API Gateway
    if 'body' in event:
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
    
    return city_name

def invoke_bedrock_agent(agent_id, agent_alias_id, session_id, input_text):
    """
    Invoke the Bedrock agent with the given input text.
    """
    try:
        response = bedrock_agent_runtime.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=input_text
        )
        
        # Process the streaming response
        completion = ""
        for event in response['completion']:
            if 'chunk' in event:
                chunk = event['chunk']
                if 'bytes' in chunk:
                    completion += chunk['bytes'].decode('utf-8')
        
        return completion
        
    except ClientError as e:
        print(f"Error invoking Bedrock agent: {e}")
        raise e

def handler(event, context):
    """
    Lambda function handler that uses a Bedrock agent to generate city facts.
    """
    try:
        # Extract city name from event
        city_name = get_city_from_event(event)
        
        # Validate input
        if not city_name:
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Allow-Methods": "POST,OPTIONS"
                },
                "body": json.dumps({
                    "error": "Missing city parameter",
                    "message": "Please provide a city name in the request",
                    "example_usage": {
                        "direct_invocation": {"city": "Tokyo"},
                        "api_gateway_body": {"body": "{\"city\": \"Tokyo\"}"},
                        "api_gateway_query": "?city=Tokyo"
                    }
                })
            }
        
        # Get agent configuration from environment variables
        agent_id = os.environ.get('BEDROCK_AGENT_ID')
        agent_alias_id = os.environ.get('BEDROCK_AGENT_ALIAS_ID', 'TSTALIASID')
        
        if not agent_id:
            return {
                "statusCode": 500,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Allow-Methods": "POST,OPTIONS"
                },
                "body": json.dumps({
                    "error": "Configuration error",
                    "message": "BEDROCK_AGENT_ID environment variable not set"
                })
            }
        session_id = context.aws_request_id  # Use request ID as session ID
        
        # Create input text for the agent that requests structured output with KB data
        input_text = f"""Please provide exactly 10 interesting facts about {city_name.strip()}. 

Format your response as a numbered list (1. 2. 3. etc.) with each fact on a new line.

Include a mix of:
- General historical, cultural, and geographical facts
- Specific data from your knowledge base about air quality, water pollution, and cost of living if available
- Modern facts about the city

If you have knowledge base data for this city, make sure to include those specific metrics in your facts."""
        
        # Invoke the Bedrock agent
        agent_response = invoke_bedrock_agent(agent_id, agent_alias_id, session_id, input_text)
        
        # Parse the agent response (it should contain the city facts)
        response = {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps({
                "city": city_name.strip().title(),
                "agent_response": agent_response,
                "message": f"City facts for {city_name} generated via Bedrock Agent",
                "agent_id": agent_id,
                "session_id": session_id,
                "requested_city": city_name,
                "source": "bedrock_agent"
            })
        }
        
        return response
        
    except Exception as e:
        print(f"Error in handler: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps({
                "error": "Internal server error",
                "message": str(e),
                "requested_city": city_name if 'city_name' in locals() else "Unknown"
            })
        }