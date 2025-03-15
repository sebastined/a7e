#source=zero_VM

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "omega_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "omega-vpc"
  }
}

resource "aws_subnet" "omega_pub_1" {
  vpc_id                  = aws_vpc.omega_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "omega-public-subnet-1"
  }
}

resource "aws_subnet" "omega_pub_2" {
  vpc_id                  = aws_vpc.omega_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "omega-public-subnet-2"
  }
}

resource "aws_subnet" "omega_pri_1" {
  vpc_id            = aws_vpc.omega_vpc.id
  cidr_block        = "10.0.253.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "omega-private-subnet-1"
  }
}

resource "aws_subnet" "omega_pri_2" {
  vpc_id            = aws_vpc.omega_vpc.id
  cidr_block        = "10.0.254.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "omega-private-subnet-2"
  }
}

resource "aws_internet_gateway" "omega_igw" {
  vpc_id = aws_vpc.omega_vpc.id
  tags = {
    Name = "omega-igw"
  }
}

resource "aws_route_table" "omega_rt" {
  vpc_id = aws_vpc.omega_vpc.id
  tags = {
    Name = "omega-public-route-table"
  }
}

resource "aws_route" "omega_int_access" {
  route_table_id         = aws_route_table.omega_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.omega_igw.id
}

resource "aws_route_table_association" "omega_pub_1" {
  subnet_id      = aws_subnet.omega_public_1.id
  route_table_id = aws_route_table.omega_rt.id
}

resource "aws_route_table_association" "omega_pub_2" {
  subnet_id      = aws_subnet.omega_public_2.id
  route_table_id = aws_route_table.omega_rt.id
}

resource "aws_security_group" "omega_sg" {
  vpc_id = aws_vpc.omega_vpc.id

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
    Name = "omega-sg"
  }
}

resource "aws_instance" "omega_web" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.omega_public_1.id
  key_name               = "nixssh"
  vpc_security_group_ids = [aws_security_group.omega_sg.id]
  tags = {
    Name = "omega-web-instance"
  }
}
