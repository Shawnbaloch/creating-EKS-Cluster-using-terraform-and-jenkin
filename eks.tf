# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# Create a VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "k8s-infra"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-eas-1" # Replace with your desired AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create a NAT Gateway for the public subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Create a security group for SSH and allow all traffic
resource "aws_security_group" "sg" {
  name        = "k8s-infra-sg"
  description = "Security group for Kubernetes infrastructure"
  vpc_id      = aws_vpc.k8s_vpc.id

  # Allow SSH and all traffic (for demonstration purposes, consider tightening this)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (for demonstration purposes, consider tightening this)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EKS cluster using Fargate
module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "java-app-prdo"
  cluster_version = "1.21"

  fargate_profiles = {
    default = {
      subnets = [aws_subnet.public_subnet.id]
    }
  }

  vpc_id = aws_vpc.k8s_vpc.id

  node_groups = {}
}

# Configure remote state in an S3 bucket
terraform {
  backend "s3" {
    bucket         = "infra-terraform-state-01"
    key            = "terraform.tfstate"
    region         = "us-east-1" # Replace with your desired region
    #encrypt        = true
    #dynamodb_table = "terraform_locks" # Optional, for state locking
  }
}
