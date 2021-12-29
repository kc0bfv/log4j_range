variable "admin_environ_portion_tag" {
  default = "admin"
}

resource "aws_subnet" "admin_public_subnet" {
  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(local.admin_ipv4_cidr_block, 6, 1)
  ipv6_cidr_block = local.admin_public_ipv6_cidr_block

  map_public_ip_on_launch = true

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.admin_environ_portion_tag
  }
}

resource "aws_subnet" "admin_internal_subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = cidrsubnet(local.admin_ipv4_cidr_block, 6, 2)
  ipv6_cidr_block      = local.admin_internal_ipv6_cidr_block
  availability_zone_id = aws_subnet.admin_public_subnet.availability_zone_id

  map_public_ip_on_launch = false

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.admin_environ_portion_tag
  }
}

resource "aws_route_table_association" "admin_rta" {
  subnet_id      = aws_subnet.admin_public_subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_key_pair" "admin_key" {
  key_name   = "admin_key"
  public_key = file("admin_key.pub")

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.admin_environ_portion_tag
  }
}

resource "aws_instance" "jump_host" {
  ami                    = var.debian_ami
  instance_type          = var.small_machine
  subnet_id              = aws_subnet.admin_public_subnet.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.allow_SSH.id, aws_security_group.allow_HTTP.id, aws_security_group.allow_HTTPS.id, aws_security_group.allow_all_local.id]
  key_name               = aws_key_pair.admin_key.key_name
  source_dest_check      = false
  depends_on             = [aws_internet_gateway.igw]

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.admin_environ_portion_tag
    Name        = "jump_host"
  }
}

resource "aws_network_interface" "jump_host_private_int" {
  subnet_id         = aws_subnet.admin_internal_subnet.id
  security_groups   = [aws_security_group.allow_everything.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.jump_host.id
    device_index = 1
  }
}

locals {
  jump_host_public_address = aws_instance.jump_host.public_ip
}

output "jump_host_public_address" {
  value = local.jump_host_public_address
}
