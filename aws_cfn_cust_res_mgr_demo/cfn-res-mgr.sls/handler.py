import json
import os
import boto3
import uuid
from botocore.vendored import requests

SUCCESS = "SUCCESS"
FAILED = "FAILED"


def send(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False):
    # From https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-lambda-function-code-cfnresponsemodule.html

    responseUrl = event['ResponseURL']

    print(responseUrl)

    responseBody = {}
    responseBody['Status'] = responseStatus
    responseBody['Reason'] = 'See the details in CloudWatch Log Stream: ' + context.log_stream_name
    responseBody['PhysicalResourceId'] = physicalResourceId or context.log_stream_name
    responseBody['StackId'] = event['StackId']
    responseBody['RequestId'] = event['RequestId']
    responseBody['LogicalResourceId'] = event['LogicalResourceId']
    responseBody['NoEcho'] = noEcho
    responseBody['Data'] = responseData

    json_responseBody = json.dumps(responseBody)

    print("Response body:\n" + json_responseBody)

    headers = {
        'content-type': '',
        'content-length': str(len(json_responseBody))
    }

    try:
        response = requests.put(responseUrl,
                                data=json_responseBody,
                                headers=headers)
        print("Status code: " + response.reason)
    except Exception as e:
        print("send(..) failed executing requests.put(..): " + str(e))


def lambda_handler(event, context):
    print(event)
    dynamodb = boto3.resource('dynamodb', region_name=event['ResourceProperties']['Region'])
    table = dynamodb.Table(os.getenv('STATE_TBL_NAME'))

    if event['RequestType'] == 'Delete':
        response = table.delete_item(
            Key={
                'resourceId': event['PhysicalResourceId']
            }
        )
        send(event, context, SUCCESS, {}, event['PhysicalResourceId'])
        return True

    PhysicalResourceId = str(uuid.uuid1())
    response = table.put_item(
        Item={
            'resourceId': PhysicalResourceId,
            'cfnResrouce': event['StackId'].split(':')[-1] + ':' + event['LogicalResourceId'],
            'type': event['ResourceProperties']['Type']
        }
    )

    send(event,
         context,
         SUCCESS,
         {},
         PhysicalResourceId)
