output "lambda_function_direct_name" {
  description = "Name of the direct model access Lambda function"
  value       = aws_lambda_function.city_facts_direct.function_name
}

output "lambda_function_direct_arn" {
  description = "ARN of the direct model access Lambda function"
  value       = aws_lambda_function.city_facts_direct.arn
}

output "lambda_function_agent_name" {
  description = "Name of the Bedrock agent Lambda function"
  value       = aws_lambda_function.city_facts_agent.function_name
}

output "lambda_function_agent_arn" {
  description = "ARN of the Bedrock agent Lambda function"
  value       = aws_lambda_function.city_facts_agent.arn
}

output "bedrock_agent_id" {
  description = "ID of the Bedrock agent"
  value       = aws_bedrockagent_agent.city_facts_agent.agent_id
}

output "bedrock_agent_arn" {
  description = "ARN of the Bedrock agent"
  value       = aws_bedrockagent_agent.city_facts_agent.agent_arn
}
# Knowledge Base Outputs
output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = local.deploy_knowledge_base ? aws_bedrockagent_knowledge_base.city_facts_simple[0].id : "Not deployed - knowledge base disabled"
}

output "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = local.deploy_knowledge_base ? aws_bedrockagent_knowledge_base.city_facts_simple[0].arn : "Not deployed - knowledge base disabled"
}

output "opensearch_collection_id" {
  description = "ID of the OpenSearch Serverless collection"
  value       = local.deploy_knowledge_base ? aws_opensearchserverless_collection.knowledge_base[0].id : "Not deployed - knowledge base disabled"
}

output "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = local.deploy_knowledge_base ? aws_opensearchserverless_collection.knowledge_base[0].arn : "Not deployed - knowledge base disabled"
}

output "opensearch_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = local.deploy_knowledge_base ? aws_opensearchserverless_collection.knowledge_base[0].collection_endpoint : "Not deployed - knowledge base disabled"
}

output "air_quality_data_source_id" {
  description = "ID of the air quality data source"
  value       = local.deploy_knowledge_base ? aws_bedrockagent_data_source.air_quality_data_simple[0].data_source_id : "Not deployed - knowledge base disabled"
}

output "cost_of_living_data_source_id" {
  description = "ID of the cost of living data source"
  value       = local.deploy_knowledge_base ? aws_bedrockagent_data_source.cost_of_living_data_simple[0].data_source_id : "Not deployed - knowledge base disabled"
}

output "s3_knowledge_base_bucket" {
  description = "Name of the S3 bucket containing knowledge base data"
  value       = local.deploy_knowledge_base ? local.knowledge_base_bucket_name : "Not deployed - knowledge base disabled"
}