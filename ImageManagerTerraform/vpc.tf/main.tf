# Backend setup
terraform {
  backend "s3" {
    key = "imgmgr-vpc.tfstate"
  }
}

provider "aws" {
  region = var.region
}

# Declare the data source to obtain available AZ's
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Creation
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-VPC"
  }
}

# creation of IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-IGW"
  }
}

# creation of Public Route Table
resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-PublicRT"
  }
}

# Public RT IGW Association
resource "aws_route" "public" {
  route_table_id         = aws_route_table.PublicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Creation of Private Route Table
resource "aws_route_table" "PrivateRT" {
  count  = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-PrivateRT-${var.private_subnet_cidr_blocks[count.index]}"
  }
}

# Private RT Nat Gateway Association
resource "aws_route" "private" {
  count                  = length(var.private_subnet_cidr_blocks)
  route_table_id         = aws_route_table.PrivateRT[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgwy[count.index].id
}

# Creation of Public Subnets
resource "aws_subnet" "publicsubnet" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-Pub-${var.public_subnet_cidr_blocks[count.index]}"
  }
}

# Creation of Private Subnets
resource "aws_subnet" "privatesubnet" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.environment}-Priv-${var.private_subnet_cidr_blocks[count.index]}"
  }
}

# Private Route Table association with Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.privatesubnet[count.index].id
  route_table_id = aws_route_table.PrivateRT[count.index].id
}

# Public Route Table association with Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.publicsubnet[count.index].id
  route_table_id = aws_route_table.PublicRT.id
}

# EIP Creation
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  vpc   = true
}


# Creation of Nat Gateways
resource "aws_nat_gateway" "natgwy" {
  count         = length(var.public_subnet_cidr_blocks)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.publicsubnet[count.index].id
  tags = {
    "Name" = "${var.environment}-PrivateNatSub-${var.private_subnet_cidr_blocks[count.index]}"
  }
}

