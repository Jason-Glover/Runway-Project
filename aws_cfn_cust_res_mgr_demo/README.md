# CFN Custom Resource Manager demo

This sample repo contains infrastructure to demonstrate how custom cloudformation resources can be created using Serverless Framework and then consumed elsewhere. The custom cloudformation resource creates entries into a DynamoDB table. An API Gateway end point is generated that exposes these inserted values as rendered icons. `icons.cfn` contains resources that will be created. Available icon parameter names include:
- head
- alarm
- cell
- hour_glass
- pd
- sql
- trash
- bell
- construction
- hammer
- key
- screen
- tag
- bomb
- crown
- squid
- tombstone


test Deploy this sample and then try different combinations or even add additional stacks.

## Deploy
AWS Cloudformation managed by:
* Serverless Framework https://github.com/serverless/serverless
* CFNgin https://github.com/runway-examples/cfngin-bucket
* Runway https://docs.onica.com/projects/runway/en/stable/

To install the above tools on your system you'll need python, pip and npm on your machine. Using pip install `pipenv`. Within the root of this project run `pipenv sync` this will install `runway` which comes packaged with CFNgin and Serverless Framework. Included is a GNU Makefile with a deploy target of `deploy-demo`, so invoke this with `make deploy-demo`.
The modules defined within `runway.yml` will be iterated through.

## Use/Distribution/Contribute
Feel free use in any way you'd like and provide feedback in issues here. The pre-req's for your workstation may be slightly different than my own. I'd like to make this as accessible as possible, so please contribute what has worked for you.
