// Landing Zone - ap-south-1 (Mumbai) with unique bucket names
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  s3_suffix = random_id.suffix.hex
}

# ---------- Networking ----------
resource "aws_vpc" "landing_zone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "LandingZoneVPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.landing_zone_vpc.id
  tags   = { Name = "LandingZoneIGW" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.landing_zone_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "LandingZonePublicSubnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.landing_zone_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "LandingZonePublicRT" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------- Security Group ----------
resource "aws_security_group" "landing_zone_sg" {
  name        = "LandingZoneSG"
  description = "Allow SSH + HTTP"
  vpc_id      = aws_vpc.landing_zone_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "LandingZoneSG" }
}

# ---------- S3 Logging Bucket ----------
resource "aws_s3_bucket" "logging" {
  bucket = "landing-zone-logs-${local.s3_suffix}"
  tags   = { Name = "landing-zone-logging-bucket" }
}

resource "aws_s3_bucket_public_access_block" "logging_pab" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logging_ver" {
  bucket = aws_s3_bucket.logging.id
  versioning_configuration { status = "Enabled" }
}

# ---------- IAM Role for EC2 (example) ----------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "landing_zone_role" {
  name               = "LandingZoneRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = { Name = "LandingZoneRole" }
}

data "aws_iam_policy_document" "landing_zone_inline" {
  statement {
    sid     = "S3ReadConfig"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.config.arn,
      
    ]
  }
}

resource "aws_iam_role_policy" "landing_zone_policy" {
  name   = "LandingZoneInlinePolicy"
  role   = aws_iam_role.landing_zone_role.id
  policy = data.aws_iam_policy_document.landing_zone_inline.json
}
