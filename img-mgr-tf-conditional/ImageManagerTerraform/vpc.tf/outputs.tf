output "vpc_id" {
  value = aws_vpc.vpc.id
  }

output "Public_Subnets" {
    value =  aws_subnet.publicsubnet.*.id
}

output "Public_Subnet1" {
    value = aws_subnet.publicsubnet[0].id
}

output "Public_Subnet2" {
    value = aws_subnet.publicsubnet[1].id
}

output "Private_Subnets" {
    value  =  aws_subnet.privatesubnet.*.id
}

output "Private_Subnet1" {
    value = aws_subnet.privatesubnet[0].id
}

output "Private_Subnet2" {
    value = aws_subnet.privatesubnet[1].id
}

output "Public_Subnets_AZs" {
    value  =  aws_subnet.publicsubnet.*.availability_zone
}

output "Private_Subnets_AZs" {
    value  =  aws_subnet.privatesubnet.*.availability_zone
}