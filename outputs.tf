output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.tor_blocker.arn
}

output "security_group_id" {
  description = "ID of the security group used for blocking TOR IPs"
  value       = aws_security_group.tor_block_sg.id
}

