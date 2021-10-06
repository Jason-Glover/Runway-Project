output "alb_dns_name" {
  value = aws_lb.alb.dns_name
  }

output "cf_dns_name" {
    value = join("",["https://",aws_cloudfront_distribution.cf.domain_name])
}