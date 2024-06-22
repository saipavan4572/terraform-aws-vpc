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