import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {"content-type": "text/html"},
        'body': "Hello World!<p>\n<pre>" + json.dumps(event, indent=4)
    }
