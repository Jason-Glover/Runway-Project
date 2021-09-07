require 'aws-sdk-dynamodb'

def lambda_handler(event:, context:)
  Aws.config.update({region: ENV['AWS_REGION']})
  @ddb = Aws::DynamoDB::Client.new
  active = @ddb.scan({table_name: ENV['STATE_TBL_NAME']}).to_h[:items]
  p event

  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*', # Required for CORS support to work
      'Access-Control-Allow-Credentials': true # Required for cookies, authorization headers with HTTPS
    },
    body: JSON.generate(active)
  }
end
