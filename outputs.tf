output "forwarder_arn" {
  description = "ARN of the Datadog Forwarder Lambda function"
  value       = aws_cloudformation_stack.datadog_forwarder.outputs["ForwarderArn"]
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.security_hub_to_datadog.arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing Datadog API key"
  value       = aws_secretsmanager_secret.datadog_api_key.arn
}
