terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bedrock-agent-testbed"
}

variable "knowledge_base_bucket_name" {
  description = "Name of the S3 bucket containing knowledge base data (created by setup-knowledge-base-s3.sh)"
  type        = string
  default     = ""
}