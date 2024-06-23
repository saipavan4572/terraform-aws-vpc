resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = var.enable_dns_hostnames # boolean flag to enable/disable DNS hostnames in the VPC - Default FALSE

  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
        #Name = "${var.project_name}-${var.environment}"
        Name = local.resource_name
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.igw_tags,
    {
        Name = local.resource_name
    }
  )
}

## Public Subnet
resource "aws_subnet" "public" { # first name is public[0], second name is public[1]
  count = length(var.public_subnet_cidrs)
  #since we need two public subnets so we are using count parameter
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true    # to map public_ip to public subnet
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_cidr_tags,
    {
        Name = "${local.resource_name}-public-${local.az_names[count.index]}"
        ##ex: expense-public-us-east-1a
        ##ex: expense-public-us-east-1b
    }
  )
}

## Private Subnet
resource "aws_subnet" "private" { # first name is private[0], second name is private[1]
  count = length(var.private_subnet_cidrs)
  #since we need two private subnets so we are using count parameter
  availability_zone = local.az_names[count.index]

  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_cidr_tags,
    {
        Name = "${local.resource_name}-private-${local.az_names[count.index]}"
        ##ex: expense-private-us-east-1a
        ##ex: expense-private-us-east-1b
    }
  )
}

## Database Subnet
resource "aws_subnet" "database" { # first name is database[0], second name is database[1]
  count = length(var.database_subnet_cidrs)
  #since we need two database subnets so we are using count parameter
  availability_zone = local.az_names[count.index]

  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.database_subnet_cidr_tags,
    {
        Name = "${local.resource_name}-database-${local.az_names[count.index]}"
        ##ex: expense-database-us-east-1a
        ##ex: expense-database-us-east-1b
    }
  )
}

### Elastic ip
resource "aws_eip" "nat" {
  domain   = "vpc"
}

### Nat Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    var.nat_gateway_tags,
    {
        Name = "${local.resource_name}" ## expense-dev 
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.

  depends_on = [aws_internet_gateway.igw]   ## this is explicit dependency

  ## nat gateway will not work without internet gateway
  ## usually terraform automatically resolves the dependencies but some times terraform will not be able to draft the dependencies.. in these cases we can add dependencies explicitly
  ## so informing terraform that, create internet gateway and then create nat gateway

}

### Public Route table ####
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "10.0.1.0/24"
  #   gateway_id = aws_internet_gateway.example.id
  # }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = merge(
    var.common_tags,
    var.public_route_table_tags,
    {
        Name = "${local.resource_name}-public" ## expense-dev-public
    }
  )
}

### Private Route table ####
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    var.private_route_table_tags,
    {
        Name = "${local.resource_name}-private" ## expense-dev-public
    }
  )
}

### Database Route table ####
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    var.database_route_table_tags,
    {
        Name = "${local.resource_name}-database" ## expense-dev-public
    }
  )
}

#### Routes ####
resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route" "private_route_nat" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route" "database_route_nat" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

#### Route table and subnet associations ####
resource "aws_route_table_association" "public" {
  # For one route table we need to associate with 2 subnets, so use count variable here
  count = length(var.public_subnet_cidrs)
  ## subnet_id      = aws_subnet.public[*].id    # public[*] - for all public subnets
  subnet_id = element(aws_subnet.public[*].id, count.index)   # to get the specific index subnet
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  # For one route table we need to associate with 2 subnets, so use count variable here
  count = length(var.private_subnet_cidrs)
  ## subnet_id      = aws_subnet.private[*].id    # private[*] - for all private subnets
  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  # For one route table we need to associate with 2 subnets, so use count variable here
  count = length(var.database_subnet_cidrs)
  ## subnet_id      = aws_subnet.database[*].id    # database[*] - for all database subnets
  subnet_id = element(aws_subnet.database[*].id, count.index)
  route_table_id = aws_route_table.database.id
}
