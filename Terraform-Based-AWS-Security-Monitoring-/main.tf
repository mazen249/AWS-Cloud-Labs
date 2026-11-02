provider "aws" {
  region = "us-east-1"
}

# Create VPC 
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "PROJECT-2-VPC"
  }
  enable_dns_support   = true
  enable_dns_hostnames = true


}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "PUBLIC-SUBNET-PROJECT-2"
  }
}

# Create private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "PRIVATE-SUBNET-PROJECT-2"
  }
}

# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW-PROJECT-2"
  }
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PUBLIC-ROUTE-TABLE-PROJECT-2"
  }
}

# Create public route table associatio
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create EIP 
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "EIP-PROJECT-2"
  }
}

# Create NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.id
  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "NAT-PROJECT-2"
  }
}

# Create Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "PRIVATE-RUTE-TABLE-PROJECT-2"
  }
}

# Create private table associatio
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create EC2
resource "aws_instance" "server_2" {
  ami           = "ami-0c230065b91270bc6"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]

  tags = {
    Name = "SERVER-2"
  }
   iam_instance_profile = aws_iam_instance_profile.lab2_profile.name
}

# Create Security Group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow "
  vpc_id      = aws_vpc.main.id


  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# Create IAM Role for EC2
resource "aws_iam_role" "lab2_role" {
  name = "LAB2-ROLE"

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

# Attach SSM permissions
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.lab2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "lab2_profile" {
  name = "LAB2-PROFILE"
  role = aws_iam_role.lab2_role.name
}

# Create CloudWatch Alarm for EC2 CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name        = "PROJECT-2-HIGH-CPU"
  alarm_description = "Alert when EC2 CPU utilization exceeds 80%"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.server_2.id
  }

  tags = {
    Name = "PROJECT-2-CPU-ALARM"
  }

  alarm_actions = [
    aws_sns_topic.cpu_alerts.arn
  ]
}

# Create SNS Topic
resource "aws_sns_topic" "cpu_alerts" {
  name = "PROJECT-2-CPU-ALERTS"

  tags = {
    Name = "PROJECT-2-CPU-ALERTS"
  }
}

# Create SNS Email Subscription
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = "mazenaref239@gmail.com"
}

# Get AWS Account ID
data "aws_caller_identity" "current" {

}

# Create S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "audit_logs" {
  bucket = "porject-2-cloudtrail-logs-mazee111"

  tags = {
    Name = "PROJECT-2-CLOUDTRAIL-LOGS"
  }
}
# Block Public Access
resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Enable Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn

        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:${data.aws_caller_identity.current.account_id}:trail/PROJECT-2-TRAIL"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:${data.aws_caller_identity.current.account_id}:trail/PROJECT-2-TRAIL"
          }
        }
      }
    ]
  })
}

# Create CloudTrail
resource "aws_cloudtrail" "project_trail" {
  name                          = "PROJECT-2-TRAIL"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy
  ]

  tags = {
    Name = "PROJECT-2-TRAIL"
  }
}

# Create EventBridge
resource "aws_cloudwatch_event_rule" "security_group_changes" {
  name        = "PROJECT-2-SG-CHANGES"
  description = "Detect Security Group ingress rule changes"

  event_pattern = jsonencode({
    source = ["aws.ec2"]

    "detail-type" = [
      "AWS API Call via CloudTrail"
    ]

    detail = {
      eventSource = ["ec2.amazonaws.com"]

      eventName = [
        "AuthorizeSecurityGroupIngress"
      ]
    }
  })

  state = "ENABLED"

  tags = {
    Name = "PROJECT-2-SG-CHANGES"
  }
}

# Create Lambda 
resource "aws_iam_role" "lambda_remediation_role" {
  name = "PROJECT-2-LAMBDA-ROLE"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "PROJECT-2-LAMBDA-ROLE"
  }
}

# Create Lambda policy
resource "aws_iam_policy" "lambda_remediation_policy" {
  name        = "PROJECT-2-LAMBDA-POLICY"
  description = "Permissions for Security Group auto-remediation"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cpu_alerts.arn
      }
    ]
  })
}
# Attach Role and Policy in Lambda
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_remediation_role.name
  policy_arn = aws_iam_policy.lambda_remediation_policy.arn
}

# Create Lambda
resource "aws_lambda_function" "security_remediation" {
  function_name = "PROJECT-2-SECURITY-REMEDIATION"
  role          = aws_iam_role.lambda_remediation_role.arn

  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  timeout = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.cpu_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]

  tags = {
    Name = "PROJECT-2-SECURITY-REMEDIATION"
  }
}

# Attach lambda & EventBßrid
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.security_group_changes.name
  target_id = "SecurityRemediationLambda"
  arn       = aws_lambda_function.security_remediation.arn
}

#
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_group_changes.arn
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}