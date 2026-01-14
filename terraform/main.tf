terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
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

variable "resource_prefix" {
  description = "Optional 3-character prefix for resource names to avoid collisions in shared AWS accounts. Common uses: developer initials (dts, sm, ak) or environment names (dev, stg, prd). Leave empty for no prefix."
  type        = string
  default     = ""
  
  validation {
    condition = var.resource_prefix == "" || (length(var.resource_prefix) <= 3 && can(regex("^[a-z0-9]+$", var.resource_prefix)))
    error_message = "Resource prefix must be empty or 1-3 lowercase alphanumeric characters."
  }
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

variable "enable_knowledge_base" {
  description = "Enable knowledge base deployment with Terraform-managed S3 bucket"
  type        = bool
  default     = true
}

variable "include_current_user_in_opensearch_access" {
  description = "Include the current AWS user in OpenSearch access policy (useful for manual index creation and debugging)"
  type        = bool
  default     = true
}

# Data source to get current AWS caller identity
data "aws_caller_identity" "current" {}

# Local values for consistent naming
locals {
  # Create the full project name with optional prefix
  full_project_name = var.resource_prefix != "" ? "${var.resource_prefix}-${var.project_name}" : var.project_name
  
  # For S3 bucket naming (no hyphens in prefix for S3)
  s3_prefix = var.resource_prefix != "" ? "${var.resource_prefix}-" : ""
  
  # Determine if knowledge base should be deployed
  deploy_knowledge_base = var.knowledge_base_bucket_name != "" || var.enable_knowledge_base
}