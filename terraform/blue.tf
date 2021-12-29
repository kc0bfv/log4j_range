variable "blue_environ_portion_tag" {
  default = "blue"
}

variable "blue_admin_subnet_number" {
  default = 2
}

resource "aws_subnet" "blue_admin_subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = cidrsubnet(local.blue_ipv4_cidr_block, 6, var.blue_admin_subnet_number)
  ipv6_cidr_block      = local.blue_admin_ipv6_cidr_block
  availability_zone_id = aws_subnet.admin_public_subnet.availability_zone_id

  map_public_ip_on_launch = false

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.blue_environ_portion_tag
  }
}

resource "aws_route_table" "blue_admin_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.jump_host_private_int.id
  }
  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = aws_network_interface.jump_host_private_int.id
  }
  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.blue_environ_portion_tag
  }
}

resource "aws_route_table_association" "blue_private_rt_assoc" {
  subnet_id      = aws_subnet.blue_admin_subnet.id
  route_table_id = aws_route_table.blue_admin_route_table.id
}

resource "aws_key_pair" "blue_key" {
  key_name   = "blue_key"
  public_key = file("blue_key.pub")

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.blue_environ_portion_tag
  }
}

resource "aws_instance" "solr_host" {
  ami                    = var.debian_ami
  instance_type          = var.medium_machine
  subnet_id              = aws_subnet.blue_admin_subnet.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.allow_everything.id]
  key_name               = aws_key_pair.blue_key.key_name

  tags = {
    Environment = var.environ_tag
    EnvPortion  = var.blue_environ_portion_tag
    Name        = "solr_host"
  }
}

locals {
  solr_host_private_address = aws_instance.solr_host.private_ip
}

output "solr_host_private_address" {
  value = local.solr_host_private_address
}
