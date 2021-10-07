######################################################################
# DNS Name of the Application Load Balancer
######################################################################

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
  }

######################################################################
# HTTPS DNS Name of the CloudFront Distribution
######################################################################

output "cf_dns_name" {
    value = join("",["https://",aws_cloudfront_distribution.cf.domain_name])
}