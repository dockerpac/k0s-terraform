data "aws_availability_zones" "all" {}

locals {
  kube_cluster_tag = "kubernetes.io/cluster/${var.cluster_name}"
  az_count = var.multi_az ? length(data.aws_availability_zones.all.names) : 1
}

# Network VPC, gateway, and routes

resource "aws_vpc" "vpc" {
  cidr_block                       = var.host_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = {
    Name = "${var.cluster_name}"
  }
}


// ######################
// PUBLIC
// ######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster_name}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public"
  }

  depends_on                = [aws_internet_gateway.igw]
}

# Public Subnet
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.all.names[count.index]

  cidr_block                      = cidrsubnet(var.host_cidr, 8, count.index)
  map_public_ip_on_launch         = true

  tags = {
    "${local.kube_cluster_tag}" = "shared"
    Name = "${var.cluster_name}-public-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)

  route_table_id = aws_route_table.public.id
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}

// ######################
// PRIVATE
// ######################
resource "aws_eip" "eip" {
  count          = length(aws_subnet.public)

  vpc = true

  tags = {
    Name = "${var.cluster_name}-${count.index}"
  }

  depends_on                = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natgateway" {
  count          = length(aws_subnet.public)

  allocation_id = element(aws_eip.eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.cluster_name}-${count.index}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  count          = length(aws_subnet.public)

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.natgateway.*.id, count.index)
  }

  tags = {
    Name = "${var.cluster_name}-private-${count.index}"
  }
}

# Private Subnets (one per availability zone)
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.all.names[count.index]

  cidr_block                      = cidrsubnet(var.host_cidr, 8, count.index+10) # +10 because 0-9 subnet is used for Public
  map_public_ip_on_launch         = false

  tags = {
    "${local.kube_cluster_tag}" = "shared"
    Name = "${var.cluster_name}-private-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)

  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}
