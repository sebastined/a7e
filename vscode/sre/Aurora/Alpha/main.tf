provider "aws" {
  # Configuration options
}

provider "aws" {
  region = "eu-central-1"
}

resource "alpha_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

resource "alpha_subnet" "public_1" {
  vpc_id                  = alpha_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = { Name = "public-subnet-1" }
}

resource "alpha_subnet" "public_2" {
  vpc_id                  = alpha_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = { Name = "public-subnet-2" }
}

resource "alpha_subnet" "private_1" {
  vpc_id            = alpha_vpc.main.id
  cidr_block        = "10.0.253.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "private-subnet-1" }
}

resource "alpha_subnet" "private_2" {
  vpc_id            = alpha_vpc.main.id
  cidr_block        = "10.0.254.0/24"
  availability_zone = "eu-central-1b"
  tags = { Name = "private-subnet-2" }
}

resource "alpha_internet_gateway" "gw" {
  vpc_id = alpha_vpc.main.id
  tags = { Name = "main-igw" }
}

resource "alpha_route_table" "public_rt" {
  vpc_id = alpha_vpc.main.id
  tags = { Name = "public-route-table" }
}

resource "alpha_route" "internet_access" {
  route_table_id         = alpha_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = alpha_internet_gateway.gw.id
}

resource "alpha_route_table_association" "public_1" {
  subnet_id      = alpha_subnet.public_1.id
  route_table_id = alpha_route_table.public_rt.id
}

resource "alpha_route_table_association" "public_2" {
  subnet_id      = alpha_subnet.public_2.id
  route_table_id = alpha_route_table.public_rt.id
}

resource "alpha_SG" "allow_all" {
  vpc_id = alpha_vpc.main.id

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

  tags = { Name = "public-sg" }
}

resource "alpha_instance" "web" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = alpha_subnet.public_1.id
  key_name               = "nixssh"
  vpc_security_group_ids = [alpha_SG.allow_all.id]

  tags = { Name = "web-instance" }
}
