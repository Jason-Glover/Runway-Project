######################################################################
# block to create Cloudformation SNS Topic 
######################################################################

resource "aws_cloudformation_stack" "sns_topic" {
  name          = "${terraform.workspace}-${var.ApplicationName}-SNS-Topic"
  template_body = <<STACK
{
    "Resources": {
        "MySNSTopic": {
            "Properties": {
                "Subscription": [
                    {
                        "Endpoint": "${var.email}",
                        "Protocol": "${var.protocol}"
                    }
                ]
            },
            "Type": "AWS::SNS::Topic"
        }
    },
    "Outputs": {
        "SNSTopicName": {
            "Value": {
                "Fn::GetAtt": [
                    "MySNSTopic",
                    "TopicName"
                ]
            }
        },
        "SNSTopicArn": {
            "Value": {
                "Ref": "MySNSTopic"
            }
        }
    }    
}
STACK
}