variable "region" {
  description = "The AWS region to deploy resources"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "The type of EC2 instance to create"
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "CIDR block for the first public subnet"
  default     = "10.0.0.0/24"
}

variable "public_subnet2_cidr" {
  description = "CIDR block for the second public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet1_cidr" {
  description = "CIDR block for the first private subnet"
  default     = "10.0.253.0/24"
}

variable "private_subnet2_cidr" {
  description = "CIDR block for the second private subnet"
  default     = "10.0.254.0/24"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  default     = "omega-key"
}