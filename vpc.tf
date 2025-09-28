#################### PRIMARY (A) ####################
resource "aws_vpc" "a" {
  cidr_block           = var.primary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc-a" }
}

locals {
  a_pub_cidrs = [cidrsubnet(var.primary_vpc_cidr, 8, 1),  cidrsubnet(var.primary_vpc_cidr, 8, 2)]
  a_app_cidrs = [cidrsubnet(var.primary_vpc_cidr, 8, 11), cidrsubnet(var.primary_vpc_cidr, 8, 12)]
  a_db_cidrs  = [cidrsubnet(var.primary_vpc_cidr, 8, 21), cidrsubnet(var.primary_vpc_cidr, 8, 22)]
}

resource "aws_subnet" "a_public" {
  for_each = { for i,c in local.a_pub_cidrs : i => { cidr=c, az=data.aws_availability_zones.a.names[i] } }
  vpc_id = aws_vpc.a.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "a-public-${each.key}" }
}

resource "aws_subnet" "a_private_app" {
  for_each = { for i,c in local.a_app_cidrs : i => { cidr=c, az=data.aws_availability_zones.a.names[i] } }
  vpc_id = aws_vpc.a.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "a-private-app-${each.key}" }
}

resource "aws_subnet" "a_private_db" {
  for_each = { for i,c in local.a_db_cidrs : i => { cidr=c, az=data.aws_availability_zones.a.names[i] } }
  vpc_id = aws_vpc.a.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "a-private-db-${each.key}" }
}

resource "aws_internet_gateway" "a" { vpc_id = aws_vpc.a.id }

resource "aws_eip" "a_nat" { domain = "vpc" }
resource "aws_nat_gateway" "a_nat" {
  allocation_id = aws_eip.a_nat.id
  subnet_id     = values(aws_subnet.a_public)[0].id
  depends_on    = [aws_internet_gateway.a]
}

resource "aws_route_table" "a_public" {
  vpc_id = aws_vpc.a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.a.id
  }
}
resource "aws_route_table_association" "a_pub_assoc" {
  for_each       = aws_subnet.a_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.a_public.id
}

# App subnets -> NAT
resource "aws_route_table" "a_private_app" {
  vpc_id = aws_vpc.a.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a_nat.id
  }
}
resource "aws_route_table_association" "a_prv_app_assoc" {
  for_each       = aws_subnet.a_private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.a_private_app.id
}

# DB subnets: NO internet route
resource "aws_route_table" "a_private_db" { vpc_id = aws_vpc.a.id }
resource "aws_route_table_association" "a_prv_db_assoc" {
  for_each       = aws_subnet.a_private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.a_private_db.id
}

################### SECONDARY (B) ###################
resource "aws_vpc" "b" {
  provider              = aws.dr
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc-b" }
}

locals {
  b_pub_cidrs = [cidrsubnet(var.secondary_vpc_cidr, 8, 1),  cidrsubnet(var.secondary_vpc_cidr, 8, 2)]
  b_app_cidrs = [cidrsubnet(var.secondary_vpc_cidr, 8, 11), cidrsubnet(var.secondary_vpc_cidr, 8, 12)]
  b_db_cidrs  = [cidrsubnet(var.secondary_vpc_cidr, 8, 21), cidrsubnet(var.secondary_vpc_cidr, 8, 22)]
}

resource "aws_subnet" "b_public" {
  provider = aws.dr
  for_each = { for i,c in local.b_pub_cidrs : i => { cidr=c, az=data.aws_availability_zones.b.names[i] } }
  vpc_id = aws_vpc.b.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "b-public-${each.key}" }
}

resource "aws_subnet" "b_private_app" {
  provider = aws.dr
  for_each = { for i,c in local.b_app_cidrs : i => { cidr=c, az=data.aws_availability_zones.b.names[i] } }
  vpc_id = aws_vpc.b.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "b-private-app-${each.key}" }
}

resource "aws_subnet" "b_private_db" {
  provider = aws.dr
  for_each = { for i,c in local.b_db_cidrs : i => { cidr=c, az=data.aws_availability_zones.b.names[i] } }
  vpc_id = aws_vpc.b.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "b-private-db-${each.key}" }
}

resource "aws_internet_gateway" "b" {
  provider = aws.dr
  vpc_id   = aws_vpc.b.id
}
resource "aws_eip" "b_nat" {
  provider = aws.dr
  domain   = "vpc"
}
resource "aws_nat_gateway" "b_nat" {
  provider      = aws.dr
  allocation_id = aws_eip.b_nat.id
  subnet_id     = values(aws_subnet.b_public)[0].id
  depends_on    = [aws_internet_gateway.b]
}

resource "aws_route_table" "b_public" {
  provider = aws.dr
  vpc_id = aws_vpc.b.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.b.id
  }
}
resource "aws_route_table_association" "b_pub_assoc" {
  provider = aws.dr
  for_each       = aws_subnet.b_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.b_public.id
}

resource "aws_route_table" "b_private_app" {
  provider = aws.dr
  vpc_id = aws_vpc.b.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.b_nat.id
  }
}
resource "aws_route_table_association" "b_prv_app_assoc" {
  provider = aws.dr
  for_each       = aws_subnet.b_private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.b_private_app.id
}

resource "aws_route_table" "b_private_db" {
  provider = aws.dr
  vpc_id   = aws_vpc.b.id
}
resource "aws_route_table_association" "b_prv_db_assoc" {
  provider = aws.dr
  for_each       = aws_subnet.b_private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.b_private_db.id
}
