variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "lambda_name" {
  description = "Name for the Lambda function"
  type        = string
  default     = "tor_blocker_lambda"
}

variable "security_group_id" {
  description = "ID of the security group to update with TOR IP blocks"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security group resides"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Lambda function"
  type        = list(string)
  default     = ["subnet-12345678", "subnet-87654321"]  # Replace with actual subnet IDs
}

variable "schedule_expression" {
  description = "Cron or rate expression for Lambda schedule (e.g., 'rate(1 hour)')"
  type        = string
  default     = "rate(1 hour)"
}

