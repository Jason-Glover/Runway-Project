/*
 Template to setup and configure Image Manager 
***********************************************
 IAM Roles and Policies are found in iam.tf  
 Security Groups are found in securitygroups.tf
 Imported Data is found in dataimports.tf
 DevENV
*/


###############################################
# Backend setup
###############################################
terraform {
  backend "s3" {
    key = "imgmgr-app.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
}

###############################################
# Provider and access setup
###############################################

provider "aws" {
  profile = "default"
  region  = var.region
  default_tags {
    tags  = {
      Environment = "${terraform.workspace}"
      Application = var.ApplicationName
    }
  }
}

###############################################
# S3 Bucket Creation
###############################################

resource "aws_s3_bucket" "imgmgr_bucket" {
  bucket_prefix = "${var.customer_name}-${terraform.workspace}-"
}

###############################################
# ALB Creation
###############################################

resource "aws_lb" "alb" {
  name               = "${terraform.workspace}-${var.ApplicationName}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = data.terraform_remote_state.remote_state.outputs.Public_Subnets
}

###############################################
# ALB Target Group
###############################################

resource "aws_lb_target_group" "alb_target" {
  name                 = "${terraform.workspace}-${var.ApplicationName}-ALB-TG"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.terraform_remote_state.remote_state.outputs.vpc_id
  deregistration_delay = 10
}

###############################################
# ALB Listener to 80 on EC2
###############################################

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

###############################################
# EC2 Bastian Host
###############################################

resource "aws_instance" "bastian" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.SSH_Key
  subnet_id              = data.terraform_remote_state.remote_state.outputs.Public_Subnet1
  vpc_security_group_ids = [aws_security_group.bastian.id]
  tags = {
    Name = "${terraform.workspace}-${var.ApplicationName}-Bastian"
  }
}

###############################################
# Create SSH Key Pair using local ssh pub key
###############################################

resource "aws_key_pair" "my_keypair" {
  key_name = terraform.workspace == "dev" ? "${var.region}_keypair" : "${terraform.workspace}-${var.region}_keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

###############################################
# Autoscaling Group
###############################################

resource "aws_autoscaling_group" "ASG" {
  name                      = "${terraform.workspace}-${var.ApplicationName}-ASG"
  max_size                  = var.ASGMax
  min_size                  = var.ASGMin
  health_check_grace_period = var.ASG_HC_GracePeriod
  health_check_type         = var.ASGHealthCheck
  desired_capacity          = var.ASGDesired
  vpc_zone_identifier       = data.terraform_remote_state.remote_state.outputs.Private_Subnets
  target_group_arns         = [aws_lb_target_group.alb_target.arn]
  launch_template {
    id      = aws_launch_template.ASG_LT.id
    version = aws_launch_template.ASG_LT.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
}

###############################################
# ASG Launch Template
###############################################

resource "aws_launch_template" "ASG_LT" {
  name                   = "${terraform.workspace}-${var.ApplicationName}-LaunchTemplate"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.my_keypair.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  update_default_version = true
  user_data              = base64encode(local.UserData)  # userdata found in userdata.tf
  iam_instance_profile {
    name = "${aws_iam_instance_profile.ec2_profile.name}"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = {
      Name = "${terraform.workspace}-${var.customer_name}-${var.ApplicationName}"
      Environment = "${terraform.workspace}"
    }
  }
}

###############################################
# ASG CPU High Scaling Policy
###############################################

resource "aws_autoscaling_policy" "asg_cpu_high" {
  name                   = "${terraform.workspace}-${var.ApplicationName}-ASG-CPUHigh-SP"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

###############################################
# ASG CPU Low Scaling Policy
###############################################

resource "aws_autoscaling_policy" "asg_cpu_low" {
  name                   = "${terraform.workspace}-${var.ApplicationName}-CPULow-SP"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

###############################################
# CPU High Alarm for CPU High Scaling Policy
###############################################

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${terraform.workspace}-${var.ApplicationName}-CPUHigh-Alarm"
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
    data.aws_cloudformation_stack.snsarn.outputs.SNSTopicArn
    ]
}

###############################################
# CPU Low Alarm for CPU Low Scaling Policy
###############################################

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${terraform.workspace}-${var.ApplicationName}-CPULow-Alarm"
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
  alarm_actions     = [aws_autoscaling_policy.asg_cpu_low.arn]
}

###############################################
# Cloudfront Distrubtion pointing to the ALB
###############################################

resource "aws_cloudfront_distribution" "cf" {
  enabled = true
  price_class = "PriceClass_100"
  
  origin {
    domain_name              = aws_lb.alb.dns_name
    origin_id                = "${terraform.workspace}-${var.ApplicationName}-CloudFront"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${terraform.workspace}-${var.ApplicationName}-CloudFront"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "/pics"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${terraform.workspace}-${var.ApplicationName}-CloudFront"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type     = "none"
    }
  }
}
