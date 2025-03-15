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

resource "aws_subnet" "omega_pub1" {
  vpc_id                  = aws_vpc.omega_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "omega-pub1"
  }
}

resource "aws_subnet" "omega_pub2" {
  vpc_id                  = aws_vpc.omega_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "omega-pub2"
  }
}

resource "aws_subnet" "omega_priv1" {
  vpc_id            = aws_vpc.omega_vpc.id
  cidr_block        = "10.0.253.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "omega-priv1"
  }
}

resource "aws_subnet" "omega_priv2" {
  vpc_id            = aws_vpc.omega_vpc.id
  cidr_block        = "10.0.254.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "omega-priv2"
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
    Name = "omega-rt"
  }
}

resource "aws_route" "omega_inet" {
  route_table_id         = aws_route_table.omega_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.omega_igw.id
}

resource "aws_route_table_association" "omega_pub_assoc1" {
  subnet_id      = aws_subnet.omega_pub1.id
  route_table_id = aws_route_table.omega_rt.id
}

resource "aws_route_table_association" "omega_pub_assoc2" {
  subnet_id      = aws_subnet.omega_pub2.id
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

# Generate SSH key pair within Terraform
resource "aws_key_pair" "omega_key" {
  key_name   = "omega-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtNj8YF0uLS7vhsRsn0lpuwmeN6XkqdpRl7SYThTZRZaeG0G41Kbp_d2o3Odx3OdGsY2dF2sXvhCU02hZbNlExmQfgvbjzk9zZmsiwBdIE4KMI0lmNqEO6nd0HgaInUw7wDfc_o_zGJgkpOBt1qEwJlQcxnAme3H9V7TYJlbf7fbFqykVZtQOSkJ1JWyT4M0VUsqIHW8ywDezqa7z7A7BjmDt8hb3Lxk5I_oXBlbGyqZHgfzT6dpvH9iWRWAc4lS3K6k7SyqumuqMyYx4lRJtLkkh7LVAITZb58Rly9PoB5FVeTQQw7IMU4wB-F_hZVJYN5xHByCtsLmrJmuwqfyZFb0_s0h1OBk9tZQ=="

  # Save private key automatically after apply
  provisioner "local-exec" {
    command = <<EOT
      echo "${aws_key_pair.omega_key.private_key}" > omega-key.pem
      chmod 600 omega-key.pem
    EOT
  }
}

# Create the EC2 instance with the generated key pair
resource "aws_instance" "omega_web" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.omega_pub1.id
  key_name               = aws_key_pair.omega_key.key_name
  vpc_security_group_ids = [aws_security_group.omega_sg.id]
  tags = {
    Name = "omega-web"
  }
}
