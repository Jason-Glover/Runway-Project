# Backend setup
terraform {
  backend "s3" {
    key = "imgmgr-app.tfstate"
  }
}

# Provider and access setup
provider "aws" {
  region = var.region
}

# Pull Data from Remote State File
data "terraform_remote_state" "remote_state" {
  backend = "s3"
  config = {
    bucket = "gloverdemo-common-tf-state-terraformstatebucket-1updgs65qx4od"
    region = "${var.region}"
    key    = "env:/common/imgmgr-vpc.tfstate"
  }
}

# S3 Bucket Creation
resource "aws_s3_bucket" "imgmgr_bucket" {}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.my-role.name
}

# create role
resource "aws_iam_role" "my-role" {
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }
    ]
}
EOF
}

# Assume AmazonEC2RoleforSSM
resource "aws_iam_role_policy_attachment" "aws-managed-policy-attachment" {
  role = "${aws_iam_role.my-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# s3 Get/Put/Delete Policy
resource "aws_iam_role_policy" "s3GetPut_Policy" {
  name   = "s3getputdelete"
  role   = aws_iam_role.my-role.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${aws_s3_bucket.imgmgr_bucket.arn}/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

# s3 List Bucket Policy
resource "aws_iam_role_policy" "s3List_Policy" {
  name   = "s3listbucket"
  role   = aws_iam_role.my-role.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "${aws_s3_bucket.imgmgr_bucket.arn}"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

# EC2 Describe tags
resource "aws_iam_role_policy" "Tags_Policy" {
  name   = "ec2desctags"
  role   = aws_iam_role.my-role.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeTags"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

# LB Security Group
resource "aws_security_group" "sg_lb" {
  name               = "LbSg-${terraform.workspace}-${var.ApplicationName}"
  description = "allow http from internet"
  vpc_id      = data.terraform_remote_state.remote_state.outputs.vpc_id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Server Security Group
resource "aws_security_group" "ec2" {
  name        = "EC2Sg-${terraform.workspace}-${var.ApplicationName}"
  description = "allow http from internet"
  vpc_id      = data.terraform_remote_state.remote_state.outputs.vpc_id
  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.sg_lb.id}",
    ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


# ALB Creation
resource "aws_lb" "alb" {
  name               = "alb-${terraform.workspace}-${var.ApplicationName}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = [
    data.terraform_remote_state.remote_state.outputs.Public_Subnet1,
    data.terraform_remote_state.remote_state.outputs.Public_Subnet2
    ]
}

# ALB Target Group
resource "aws_lb_target_group" "alb_target" {
  name     = "alb-tg-${terraform.workspace}-${var.ApplicationName}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.remote_state.outputs.vpc_id
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type            = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "ASG" {
  name                      = "asg-${terraform.workspace}-${var.ApplicationName}"
  max_size                  = var.ASGMax
  min_size                  = var.ASGMin
  health_check_grace_period = var.ASG_HC_GracePeriod
  health_check_type         = var.ASGHealthCheck
  desired_capacity          = var.ASGDesired
  vpc_zone_identifier       = [
    data.terraform_remote_state.remote_state.outputs.Private_Subnet1,
    data.terraform_remote_state.remote_state.outputs.Private_Subnet2
    ]
  target_group_arns         = [aws_lb_target_group.alb_target.arn]
  launch_template {
    id      = aws_launch_template.ASG_LT.id
    version = "$Latest"
  }
}

# ASG Launch Template
resource "aws_launch_template" "ASG_LT" {
  name                   = "lt-${terraform.workspace}-${var.ApplicationName}"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.SSH_Key
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = base64encode(templatefile("${path.module}\\templates\\userdata.sh", { S3Bucket = aws_s3_bucket.imgmgr_bucket.id }))
  iam_instance_profile {
    name = "${aws_iam_instance_profile.ec2_profile.name}"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.customer_name}-${var.ApplicationName}"
      Environment = "${var.environment}"
    }
  }
}

# ASG CPU High Scaling Policy
resource "aws_autoscaling_policy" "asg_cpu_high" {
  name                   = "ASG-CPU-High-${terraform.workspace}-${var.ApplicationName}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

# ASG CPU Low Scaling Policy
resource "aws_autoscaling_policy" "asg_cpu_low" {
  name                   = "ASG-CPU-Low-${terraform.workspace}-${var.ApplicationName}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

# CPU High Alarm for CPU High Scaling Policy
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${terraform.workspace}-${var.ApplicationName}-CPU-High-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "${var.CPUHighPolicy}"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ASG.name
  }

  alarm_description = "This metric monitors ec2 ASG high cpu utilization"
  alarm_actions     = [
    aws_autoscaling_policy.asg_cpu_high.arn,
    data.aws_cloudformation_export.snsarn.value
    ]
}

# CPU Low Alarm for CPU Low Scaling Policy
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${terraform.workspace}-${var.ApplicationName}-CPU-Low-Alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "${var.CPULowPolicy}"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ASG.name
  }

  alarm_description = "This metric monitors ec2 ASG low cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_cpu_high.arn]
}

# Data to import from Cloudformation Stack
data "aws_cloudformation_export" "snsarn" {
  depends_on = [aws_cloudformation_stack.sns_topic]
  name = "TFIMGMGR-SNSTopicArn"
}

# block to create Cloudformation SNS Topic
resource "aws_cloudformation_stack" "sns_topic" {
  name          = "${terraform.workspace}-Img-Mgr-SNS-Topic"
  template_body = <<STACK
{
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
    },
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
    }
}
STACK
}

