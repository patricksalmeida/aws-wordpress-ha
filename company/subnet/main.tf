locals {
  identifier = var.identifier != null ? "-${var.identifier}" : ""
}

resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "sn-${var.public ? "public" : "private"}${local.identifier}"
  }
}

resource "aws_eip" "eip" {
  count  = var.public == false ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "eip-ng-private${local.identifier}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count             = var.public == false ? 1 : 0
  subnet_id         = var.nat_gateway_subnet_id
  allocation_id     = aws_eip.eip[0].id
  connectivity_type = "public"

  tags = {
    Name = "ng-private${local.identifier}"
  }
}

resource "aws_route_table" "rt_private" {
  count  = var.public == false ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
  }

  tags = {
    Name = "rt-private${local.identifier}"
  }
}

resource "aws_route_table_association" "rt_private_association" {
  count          = var.public == false ? 1 : 0
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt_private[0].id
}

resource "aws_route_table" "rt_public" {
  count  = var.public == true ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "rt-public${local.identifier}"
  }
}

resource "aws_route_table_association" "rt_public_association" {
  count          = var.public == true ? 1 : 0
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt_public[0].id
}
