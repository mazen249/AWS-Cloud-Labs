provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-PROJECT-1"

  }

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Pubic-Subnet"
  }
}

# Create Private Subnet 
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-Subnet"
  }
}

# Crate Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW-PROJECT-1"
  }
}

# Create Public route table 
resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PUBLIC-TABLE"
  }
}

# Create Public route table association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_table.id
}

# Create Elastic ip
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "PROJECT-1-EIP"
  }
}

# Create NAT 
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "PROJECT-1-NAT"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Create Private route table
resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "PRIVATE-TABLE"
  }
}

# Create Private route table association
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_table.id

}

# Create security group
resource "aws_security_group" "main" {
  name        = "allow_tls"
  description = "Allow"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "SUCRITY-PROJECT-1"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Create Instance 

resource "aws_instance" "server_1" {
    ami = "ami-041607313c6a2a618"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.private.id
    vpc_security_group_ids = [ 
        aws_security_group.main.id 
    ]
    availability_zone = "us-east-1d"
    
    tags = {
      Name = "PROJECT-1-SERVER"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}
 

# Create CloudWatch Alarm for EC2 CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "PROJECT-1-HIGH-CPU"
  alarm_description   = "Alert when EC2 CPU utilization exceeds 80%"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.server_1.id
  }

  tags = {
    Name = "PROJECT-1-CPU-ALARM"
  }
}


# 1. Create IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "PROJECT-1-EC2-ROLE"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "PROJECT-1-EC2-ROLE"
  }
}

# 2. Attach SSM permissions to the role
resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3. Create IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "PROJECT-1-EC2-PROFILE"
  role = aws_iam_role.ec2_role.name
}
