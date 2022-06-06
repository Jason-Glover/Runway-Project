variable "region" {
  description = "AWS region"
  type        = string
}

variable "email" {
  description = "SNS Endpoint Email Address"
  type        = string
  default     = "tony.fruzza@rackspace.com"
}

variable "protocol" {
  description = "SNS Protocol"
  type        = string
  default     = "email"
}

variable "customer_name" {
  description = "Customer Name for this Deployment"
  type        = string
  default     = "gloverdemo"
}

variable "ApplicationName" {
  description = "Name of the deployed application"
  type        = string
  default     = "img-mgr"
}

variable "SSH_Key" {
  description = "SSH Key to use for EC2 Instances"
  type        = string
  default     = "best-customer-us-east-2"
}

variable "ami_id" {
  description = "Amazon AMI ID Image to apply to EC2"
  type        = string
  default     = "ami-087c17d1fe0178315"
}

variable "ASGHealthCheck" {
  description = "types can be ELB or EC2"
  type        = string
  default     = "ELB"
}

variable "ASG_HC_GracePeriod" {
  description = "ASG Health Check Grace Period"
  type        = number
  default     = 300
}

variable "ASGMin" {
  description = "Minimum Number of EC2 Instances running in the ASG"
  type        = number
  default     = 2
}

variable "ASGMax" {
  description = "Maximum Number of EC2 Instances running in the ASG"
  type    = number
  default = 4
}

variable "ASGDesired" {
  description = "Desired Number of EC2 Instances running in the ASG"
  type    = number
  default = 2
}

variable "CPUHighPolicy" {
  description = "CPU Alarm High Threshold"
  type        = string
  default     = "50"
}

variable "CPULowPolicy" {
  description = "CPU Alarm Low Threshold"
  type        = string
  default     = "15"
}

variable "instance_type" {
  description = "Type of EC2 Instance to Deploy"
  type        = string
  default     = "t2.small"
}
