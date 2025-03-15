provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "aur_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "aur-vpc"
  }
}

resource "aws_subnet" "aur_public_1" {
  vpc_id                  = aws_vpc.aur_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "aur-public-subnet-1"
  }
}

resource "aws_subnet" "aur_public_2" {
  vpc_id                  = aws_vpc.aur_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "aur-public-subnet-2"
  }
}

resource "aws_subnet" "aur_private_1" {
  vpc_id            = aws_vpc.aur_vpc.id
  cidr_block        = "10.0.253.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "aur-private-subnet-1"
  }
}

resource "aws_subnet" "aur_private_2" {
  vpc_id            = aws_vpc.aur_vpc.id
  cidr_block        = "10.0.254.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "aur-private-subnet-2"
  }
}

resource "aws_internet_gateway" "aur_igw" {
  vpc_id = aws_vpc.aur_vpc.id
  tags = {
    Name = "aur-igw"
  }
}

resource "aws_route_table" "aur_rt" {
  vpc_id = aws_vpc.aur_vpc.id
  tags = {
    Name = "aur-public-route-table"
  }
}

resource "aws_route" "aur_internet_access" {
  route_table_id         = aws_route_table.aur_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aur_igw.id
}

resource "aws_route_table_association" "aur_public_assoc_1" {
  subnet_id      = aws_subnet.aur_public_1.id
  route_table_id = aws_route_table.aur_rt.id
}

resource "aws_route_table_association" "aur_public_assoc_2" {
  subnet_id      = aws_subnet.aur_public_2.id
  route_table_id = aws_route_table.aur_rt.id
}

resource "aws_security_group" "aur_sg" {
  vpc_id = aws_vpc.aur_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aur-sg"
  }
}

resource "aws_instance" "aur_web" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.aur_public_1.id
  key_name               = "nixssh"
  vpc_security_group_ids = [aws_security_group.aur_sg.id]
  tags = {
    Name = "aur-web-instance"
  }
}
