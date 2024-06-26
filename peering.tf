resource "aws_vpc_peering_connection" "peering" {
    count = var.is_peering_required ? 1 : 0
  # peer_owner_id = var.peer_owner_id
  vpc_id        = aws_vpc.main.id    # requestor VPC
  peer_vpc_id   = var.acceptor_vpc_id == "" ? data.aws_vpc.default.id : var.acceptor_vpc_id
  auto_accept   = var.acceptor_vpc_id == "" ? true : false

  ## auto accept can work if with in the same account
  ## if within the same account, we have the access to the peering VPC(default) we can accept
  ## if diff. account/regions, then we need to inform to peering VPC team to accept request for peering to their VPC.
  
  tags = merge(
    var.common_tags,
    var.vpc_peering_tags,
    {
        Name = local.resource_name  # expense-dev
    }
  )
}


resource "aws_route" "public_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    # count is useful to control when resource is required
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block   # default VPC cidr_block
  ##since we are using count variable - it should be list. so we have to provide the specific index even though if there is only one value - use specific index or count.index
  #vpc_peering_connection_id = aws_vpc_peering_connection.peering[count.index].id
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "private_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    # count is useful to control when resource is required
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block   # default VPC cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "database_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    # count is useful to control when resource is required
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block   # default VPC cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

## if we create a VPC then by default one "main" route table(main=yes) will be created
resource "aws_route" "default_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
  route_table_id            = data.aws_route_table.main.id   ##default VPC route table
  destination_cidr_block    = var.vpc_cidr                   ##expense vpc cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}