provider "aws" {
  region = "eu-central-1" # Change to your preferred region
}

# Create a VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "custom-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "custom-igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a security group for Elastic Beanstalk
resource "aws_security_group" "beanstalk_sg" {
  vpc_id = aws_vpc.custom_vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "beanstalk-sg"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket for the Flask application
resource "aws_s3_bucket" "app_bucket" {
  bucket = "flask-app-bucket-${random_id.suffix.hex}" # Unique bucket name
  force_destroy = true
}

# Upload the Flask application to S3
resource "aws_s3_object" "app_files" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "flask-app.zip"
  source = "./flask-app.zip"
  etag = filemd5("./flask-app.zip")
  depends_on = [aws_s3_bucket.app_bucket]
}

# IAM Role for Elastic Beanstalk EC2 instances
resource "aws_iam_role" "beanstalk_ec2_role" {
  name = "beanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  name = "beanstalk-ec2-profile"
  role = aws_iam_role.beanstalk_ec2_role.name
}

# Attach IAM policies for Elastic Beanstalk
resource "aws_iam_role_policy_attachment" "beanstalk_ec2_policy" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_s3_policy" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "flask_app" {
  name = "flask-app"
}

# Elastic Beanstalk Application Version (Links ZIP file from S3)
resource "aws_elastic_beanstalk_application_version" "flask_app_version" {
  name        = "flask-app-v1"
  application = aws_elastic_beanstalk_application.flask_app.name
  description = "Initial version of Flask app"
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.app_files.key

  depends_on = [aws_s3_object.app_files]
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "flask_env" {
  name                = "flask-app-env"
  application         = aws_elastic_beanstalk_application.flask_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.0 running Python 3.11"
  version_label       = aws_elastic_beanstalk_application_version.flask_app_version.name

  depends_on = [
    aws_elastic_beanstalk_application.flask_app,
    aws_iam_instance_profile.beanstalk_ec2_profile,
    aws_security_group.beanstalk_sg
  ]

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.custom_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.public_subnet.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_sg.id
  }
}
