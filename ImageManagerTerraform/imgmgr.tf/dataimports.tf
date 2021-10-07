######################################################################
# Data to import from Cloudformation Stack
######################################################################

data "aws_cloudformation_export" "snsarn" {
  depends_on = [aws_cloudformation_stack.sns_topic]
  name = "TFIMGMGR-SNSTopicArn"
}

######################################################################
# Data to import from Remote State File
######################################################################

data "terraform_remote_state" "remote_state" {
  backend = "s3"
  config = {
    bucket = "gloverdemo-common-tf-state-terraformstatebucket-1updgs65qx4od"
    region = "${var.region}"
    key    = "env:/common/imgmgr-vpc.tfstate"
  }
}