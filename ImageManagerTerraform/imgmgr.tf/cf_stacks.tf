# block to create Cloudformation SNS Topic 
# !!! Exports in this Code Block are Specific to Region US-EAST-1 !!!
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
            "Export": {
                "Name": "TFIMGMGR-SNSTopicName"
            },
            "Value": {
                "Fn::GetAtt": [
                    "MySNSTopic",
                    "TopicName"
                ]
            }
        },
        "SNSTopicArn": {
            "Export": {
                "Name": "TFIMGMGR-SNSTopicArn"
            },
            "Value": {
                "Ref": "MySNSTopic"
            }
        }
    }    
}
STACK
}