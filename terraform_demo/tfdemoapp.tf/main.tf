# Backend setup
terraform {
  backend "s3" {
    key = "sampleapp.tfstate"
  }
}



# Provider and access setup
provider "aws" {
  version = "~> 2.0"
  region = "${var.region}"
}

# CloudFormation Stack Call
data "aws_cloudformation_stack" "hello_world_lambda_stack" {
  name = "hello-world-${terraform.workspace}"
}

# Data and resources
resource "aws_sqs_queue" "terraform_queue" {
  delay_seconds = 90
}

# DEMO SNS Topic
resource "aws_sns_topic" "demo_sns_topic" {
  name = "Demo-Terraform-Topic"
}

#DEMO SNS Topic Subscription to SQS Queeu
resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = aws_sns_topic.demo_sns_topic.arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.terraform_queue.arn
  raw_message_delivery = true
} 

# Policy to allow SNS to communicate with SQS
resource "aws_sqs_queue_policy" "terraform_queue_policy" {
  queue_url = aws_sqs_queue.terraform_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.terraform_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.demo_sns_topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

# Policy to allow SNS to communicate with Lambda
resource "aws_lambda_permission" "perms_for_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_cloudformation_stack.hello_world_lambda_stack.outputs["LamdaName"]
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.demo_sns_topic.arn
}



#Lambda subscription to SNS DEMO Topic
resource "aws_sns_topic_subscription" "lambda_subscriber" {
  topic_arn = aws_sns_topic.demo_sns_topic.arn
  protocol = "lambda"
  endpoint = data.aws_cloudformation_stack.hello_world_lambda_stack.outputs["LambdaARN"]
}