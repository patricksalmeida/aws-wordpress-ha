resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

module "public_subnet_1" {
  source            = "./subnet"
  public            = true
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.az.names, 0)
  cidr_block        = "10.0.1.0/24"
  igw_id            = aws_internet_gateway.main_igw.id
  identifier        = 1
}

module "public_subnet_2" {
  source            = "./subnet"
  public            = true
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.az.names, 1)
  cidr_block        = "10.0.2.0/24"
  igw_id            = aws_internet_gateway.main_igw.id
  identifier        = 2
}

module "private_subnet_1" {
  source                = "./subnet"
  vpc_id                = aws_vpc.main.id
  availability_zone     = element(data.aws_availability_zones.az.names, 0)
  cidr_block            = "10.0.3.0/24"
  nat_gateway_subnet_id = module.public_subnet_1.id
  identifier            = "app-1"
}

module "private_subnet_2" {
  source                = "./subnet"
  vpc_id                = aws_vpc.main.id
  availability_zone     = element(data.aws_availability_zones.az.names, 1)
  cidr_block            = "10.0.4.0/24"
  nat_gateway_subnet_id = module.public_subnet_2.id
  identifier            = "app-2"
}

module "private_subnet_3" {
  source                = "./subnet"
  vpc_id                = aws_vpc.main.id
  availability_zone     = element(data.aws_availability_zones.az.names, 0)
  cidr_block            = "10.0.5.0/24"
  nat_gateway_subnet_id = module.public_subnet_1.id
  identifier            = "data-1"
}

module "private_subnet_4" {
  source                = "./subnet"
  vpc_id                = aws_vpc.main.id
  availability_zone     = element(data.aws_availability_zones.az.names, 1)
  cidr_block            = "10.0.6.0/24"
  nat_gateway_subnet_id = module.public_subnet_2.id
  identifier            = "data-2"
}
