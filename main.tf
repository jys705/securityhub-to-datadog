# AWS Security Hub to Datadog Integration
# This Terraform configuration automates the setup of forwarding Security Hub findings to Datadog

# 1. Datadog API 키를 Secrets Manager에 저장
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "datadog_api_key"
  description = "Datadog API Key for Forwarder"
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key  # 변수로 제공
}

# 2. Datadog Forwarder 설치
resource "aws_cloudformation_stack" "datadog_forwarder" {
  name         = "datadog-forwarder"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  
  parameters = {
    DdApiKeySecretArn = aws_secretsmanager_secret.datadog_api_key.arn
    DdSite            = var.datadog_site
    FunctionName      = "datadog-forwarder"
  }
  
  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/forwarder/latest.yaml"
}

# 3. EventBridge 규칙 생성
resource "aws_cloudwatch_event_rule" "security_hub_to_datadog" {
  name        = "security-hub-to-datadog"
  description = "Send Security Hub findings to Datadog"
  
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
  })
}

# 4. EventBridge 타겟 설정 (Datadog Forwarder)
resource "aws_cloudwatch_event_target" "datadog_forwarder" {
  rule      = aws_cloudwatch_event_rule.security_hub_to_datadog.name
  target_id = "DatadogForwarder"
  arn       = aws_cloudformation_stack.datadog_forwarder.outputs["ForwarderArn"]
}

# 5. Lambda 권한 부여 (EventBridge가 Lambda 호출)
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = "datadog-forwarder"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_to_datadog.arn
  
  depends_on = [aws_cloudformation_stack.datadog_forwarder]
}
