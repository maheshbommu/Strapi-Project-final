########################################
# AWS Provider
########################################
provider "aws" {
  region = "us-east-1"
}

########################################
# Key Pair
########################################
resource "aws_key_pair" "awskey" {
  key_name   = "awskey"
  public_key = file("./id_ed25519.pub")
}

########################################
# S3 Bucket for Strapi Uploads
########################################
resource "aws_s3_bucket" "strapi_uploads" {
  bucket        = "strapi-uploads-bucket-us-east-1"
  force_destroy = true

  tags = {
    Name = "strapi_uploads_bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "strapi_uploads_pab" {
  bucket = aws_s3_bucket.strapi_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

########################################
# IAM Role for EC2 → S3 Access
########################################
resource "aws_iam_role" "ec2_role" {
  name = "ec2_strapi_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_policy" {
  name = "ec2_s3_full_access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:*"],
      Resource = ["${aws_s3_bucket.strapi_uploads.arn}", "${aws_s3_bucket.strapi_uploads.arn}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_s3_instance_profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# VPC
########################################
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "main_vpc_us_east" }
}

########################################
# Internet Gateway
########################################
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "main_igw_us_east" }
}

########################################
# Public Subnet 1a
########################################
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "public_subnet_1a_us_east" }
}

########################################
# Public Subnet 1b
########################################
resource "aws_subnet" "public_subnet_1b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "public_subnet_1b_us_east" }
}

########################################
# Route Table
########################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = { Name = "public_rt_us_east" }
}

resource "aws_route_table_association" "public_assoc_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_1b" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# Security Group Allow All
########################################
resource "aws_security_group" "allow_all_sg" {
  name        = "allow_all_sg_us_east"
  description = "Allow all inbound/outbound for testing"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "allow_all_sg_us_east" }
}

########################################
# RDS Security Group (MySQL)
########################################
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg_us_east"
  description = "Allow MySQL inbound from EC2"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_all_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds_sg_us_east" }
}

########################################
# MySQL RDS Instance
########################################
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "main_rds_subnet_group"

  subnet_ids = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id
  ]

  tags = { Name = "main_rds_subnet_group_us_east" }
}

resource "aws_db_instance" "mysql_rds" {
  identifier            = "mysql-rds-instance"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  db_name               = "mydatabase"
  username              = "mahesh"
  password              = "mahesh123"

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true

  tags = { Name = "mysql_rds_us_east" }
}

########################################
# EC2 Instance for Strapi
########################################
resource "aws_instance" "nodejs_instance" {
  ami                    = "ami-04a81a99f5ec58529" # Ubuntu 24.04 us-east-1
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.allow_all_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  key_name = aws_key_pair.awskey.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y curl
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt install -y nodejs
              EOF

  tags = { Name = "EC2_Strapi_US_EAST" }
}
