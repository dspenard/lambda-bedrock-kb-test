#!/usr/bin/env python3
"""
Create OpenSearch Serverless vector index for Bedrock Knowledge Base
"""

import json
import sys
import time

try:
    from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
    import boto3
except ImportError:
    print("❌ Error: Required Python packages not installed")
    print("   Install with: pip3 install opensearch-py boto3")
    sys.exit(1)


def create_index(collection_endpoint, index_name="bedrock-knowledge-base-default-index"):
    """Create vector index in OpenSearch Serverless collection"""
    
    print(f"🔍 Creating OpenSearch vector index...")
    print(f"   Endpoint: {collection_endpoint}")
    print(f"   Index: {index_name}")
    
    # Get AWS credentials
    session = boto3.Session()
    credentials = session.get_credentials()
    region = session.region_name or 'us-east-1'
    
    auth = AWSV4SignerAuth(credentials, region, 'aoss')
    
    # Parse endpoint
    host = collection_endpoint.replace('https://', '').replace('http://', '')
    
    # Create client
    client = OpenSearch(
        hosts=[{'host': host, 'port': 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=300
    )
    
    # Index configuration
    index_body = {
        "settings": {
            "index": {
                "knn": True,
                "number_of_shards": 2,
                "number_of_replicas": 0
            }
        },
        "mappings": {
            "properties": {
                "embeddings": {
                    "type": "knn_vector",
                    "dimension": 1536,
                    "method": {
                        "name": "hnsw",
                        "space_type": "l2",
                        "engine": "faiss"
                    }
                },
                "text": {
                    "type": "text"
                },
                "bedrock-metadata": {
                    "type": "text",
                    "index": False
                }
            }
        }
    }
    
    try:
        # Check if exists
        if client.indices.exists(index=index_name):
            print(f"✅ Index '{index_name}' already exists")
            return True
        
        # Create index
        response = client.indices.create(index=index_name, body=index_body)
        print(f"✅ Index '{index_name}' created successfully")
        return True
        
    except Exception as e:
        if "resource_already_exists" in str(e).lower():
            print(f"✅ Index '{index_name}' already exists")
            return True
        print(f"❌ Error: {e}")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 create-opensearch-index.py <collection-endpoint>")
        sys.exit(1)
    
    endpoint = sys.argv[1]
    success = create_index(endpoint)
    sys.exit(0 if success else 1)
