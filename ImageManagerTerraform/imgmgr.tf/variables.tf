variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "email" {
  type    = string
  default = "jason.glover@rackspace.com"
}

variable "protocol" {
  description = "SNS Protocol"
  type        = string
  default     = "email"
}

variable "customer_name" {
  type    = string
  default = "GloverDemo"
}

variable "ApplicationName" {
  type    = string
  default = "img-mgr"
}

variable "SSH_Key" {
  type    = string
  default = "virginiakp"
}

variable "ami_id" {
  type    = string
  default = "ami-087c17d1fe0178315"
}

variable "ASGHealthCheck" {
  description = "types can be ELB or EC2"
  type        = string
  default     = "ELB"
}

variable "ASG_HC_GracePeriod" {
  type    = number
  default = 300
}

variable "ASGMin" {
  type    = number
  default = 2
}

variable "ASGMax" {
  type    = number
  default = 4
}

variable "ASGDesired" {
  type    = number
  default = 2
}

variable "CPUHighPolicy" {
  type    = string
  default = "50"
}

variable "CPULowPolicy" {
  type    = string
  default = "15"
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}
