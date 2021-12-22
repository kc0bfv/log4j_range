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
  default = "log4j"
}

variable "debian_ami" {
  # Debian 10.11 64bit AMD us-east-2
  # https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
  description = "AMI - Debian 10.11 64bit AMD us-east-2"
  default     = "ami-0d90bed76900e679a"
}

variable "kali_ami" {
  description = "AMI - Kali 2021.4 Dec 8 2021 us-east-2 64-bit x86"
  default     = "ami-0d12596b1b9089744"
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

variable "range_ipv4_cidr_block" {
  default = "10.18.0.0/16"
}

locals {
  admin_ipv4_cidr_block = cidrsubnet(var.range_ipv4_cidr_block, 2, 0)
  blue_ipv4_cidr_block  = cidrsubnet(var.range_ipv4_cidr_block, 2, 1)
  red_ipv4_cidr_block   = cidrsubnet(var.range_ipv4_cidr_block, 2, 3)

  first_qtr_ipv6_cidr_block  = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 2, 0)
  second_qtr_ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 2, 1)
  third_qtr_ipv6_cidr_block  = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 2, 2)

  admin_public_ipv6_cidr_block   = cidrsubnet(local.first_qtr_ipv6_cidr_block, 6, 1)
  admin_internal_ipv6_cidr_block = cidrsubnet(local.first_qtr_ipv6_cidr_block, 6, 2)
  blue_admin_ipv6_cidr_block     = cidrsubnet(local.second_qtr_ipv6_cidr_block, 6, 1)
  red_ipv6_cidr_block            = cidrsubnet(local.third_qtr_ipv6_cidr_block, 6, 1)
}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.range_ipv4_cidr_block
  assign_generated_ipv6_cidr_block = true

  tags = { Environment = var.environ_tag }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

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
  name        = "allow_everything"
  description = "Allow everything"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "All Ingress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
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
}

resource "aws_security_group" "allow_only_egress" {
  name        = "allow_only_egress"
  description = "Allow only egress"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description      = "All Egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_all_local" {
  name        = "allow_all_local"
  description = "Allow all local"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "All Local Ingress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.range_ipv4_cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc.ipv6_cidr_block]
  }

  egress {
    description      = "All Local Egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.range_ipv4_cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc.ipv6_cidr_block]
  }
}
