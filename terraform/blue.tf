terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "aws_admin"
  region  = "us-east-2"
}

variable "environ_tag" {
  default = "log4j_blue"
}

variable "debian_ami" {
  # Debian 10.11 64bit AMD us-east-2
  # https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
  default = "ami-0d90bed76900e679a"
}

variable "small_machine" {
  # $.0188 per hour, 2 GB RAM, 2 CPUs
  default = "t3a.small"
}

variable "medium_machine" {
  # $.0376 per hour, 4 GB RAM, 2 CPUs
  default = "t3a.medium"
}

variable "large_machine" {
  # $.0752 per hour, 8 GB RAM, 2 CPUs
  default = "t3a.large"
}

variable "ipv4_cidr_block" {
  default = "10.18.0.0/16"
}

variable "public_subnet_number" {
  default = 0
}

variable "admin_subnet_number" {
  default = 2
}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.ipv4_cidr_block
  assign_generated_ipv6_cidr_block = true

  tags = { Environment = var.environ_tag }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Environment = var.environ_tag }
}

resource "aws_subnet" "public_subnet" {
  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.public_subnet_number)
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, var.public_subnet_number)

  map_public_ip_on_launch = true

  tags = { Environment = var.environ_tag }
}

resource "aws_subnet" "admin_subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.admin_subnet_number)
  ipv6_cidr_block      = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, var.admin_subnet_number)
  availability_zone_id = aws_subnet.public_subnet.availability_zone_id

  map_public_ip_on_launch = false

  tags = { Environment = var.environ_tag }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = { Environment = var.environ_tag }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "allow_none" {
  name        = "allow_none"
  description = "Allow Nothing"
  vpc_id      = aws_vpc.vpc.id

  tags = { Environment = var.environ_tag }
}

resource "aws_security_group" "allow_admin" {
  name        = "allow_admin"
  description = "Allow RDP and SSH"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "RDP from anywhere"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All Egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Environment = var.environ_tag }
}

resource "aws_security_group" "allow_everything" {
    name = "allow_everything"
    description = "Allow everything"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "All Ingress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress {
        description = "All Egress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = file("key.pub")

  tags = { Environment = var.environ_tag }
}

resource "aws_instance" "jump_host" {
  ami                    = var.debian_ami
  instance_type          = var.small_machine
  subnet_id              = aws_subnet.public_subnet.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.allow_admin.id]
  key_name               = aws_key_pair.key.key_name
  depends_on             = [aws_internet_gateway.igw]

  tags = {
    Environment = var.environ_tag
    Name        = "jump_host"
  }
}

resource "aws_network_interface" "int_priv" {
  subnet_id       = aws_subnet.admin_subnet.id
  security_groups = [aws_security_group.allow_everything.id]
  attachment {
    instance     = aws_instance.jump_host.id
    device_index = 1
  }
}

resource "aws_instance" "elastic_host" {
  ami                    = var.debian_ami
  instance_type          = var.medium_machine
  subnet_id              = aws_subnet.admin_subnet.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.allow_everything.id]
  key_name               = aws_key_pair.key.key_name

  tags = {
    Environment = var.environ_tag
    Name        = "elastic_host"
  }
}

output "jump_host_public_address" {
  value = aws_instance.jump_host.public_ip
}

output "elastic_host_private_address" {
  value = aws_instance.elastic_host.private_ip
}
