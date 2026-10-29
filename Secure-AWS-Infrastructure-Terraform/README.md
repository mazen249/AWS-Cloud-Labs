# Secure AWS Infrastructure with Terraform

A hands-on Infrastructure as Code (IaC) project that uses Terraform to provision AWS networking infrastructure, manage private EC2 access, and monitor system performance with Amazon CloudWatch.

## Project Overview

The goal of this project is to build a segmented AWS network with public and private subnets, controlled routing, secure instance management, and basic monitoring.

The infrastructure is managed using Terraform, making it easier to review, reproduce, and maintain AWS resources through code.

## Project Objectives

- Create a custom Amazon VPC.
- Configure public and private subnets.
- Connect the VPC to the internet using an Internet Gateway.
- Configure a NAT Gateway with an Elastic IP.
- Create public and private route tables.
- Configure Security Groups to control network traffic.
- Create an IAM role and instance profile for EC2.
- Deploy an EC2 instance in a private subnet.
- Configure AWS Systems Manager access.
- Monitor EC2 CPU utilization using CloudWatch.
- Practice Infrastructure as Code principles with Terraform.

## Architecture

The project uses a custom VPC with separate public and private subnets.

- **Public subnet:** Hosts network infrastructure that requires public-subnet placement, including the NAT Gateway.
- **Private subnet:** Hosts the EC2 workload without requiring direct inbound internet access.
- **Internet Gateway:** Provides an internet gateway attachment for the VPC.
- **NAT Gateway:** Allows eligible private-subnet resources to initiate outbound IPv4 connections.
- **Route tables:** Control traffic routing for each subnet.
- **IAM:** Provides permissions for EC2 to use AWS Systems Manager.
- **CloudWatch:** Monitors EC2 CPU utilization.

### AWS Resource Map



## Network Configuration

| Component           | Configuration                  | Purpose                                              |
| ------------------- | ------------------------------ | ---------------------------------------------------- |
| AWS Region          | `us-east-1`                    | Northern Virginia                                    |
| VPC                 | `10.0.0.0/16`                  | Main virtual network                                 |
| Public Subnet       | `10.0.1.0/24`                  | Public network infrastructure                        |
| Private Subnet      | `10.0.2.0/24`                  | Private EC2 workload                                 |
| Internet Gateway    | Attached to VPC                | Provides internet routing                            |
| Public Route Table  | `0.0.0.0/0 → Internet Gateway` | Routes public-subnet internet traffic                |
| NAT Gateway         | Public subnet with Elastic IP  | Provides outbound connectivity for private resources |
| Private Route Table | `0.0.0.0/0 → NAT Gateway`      | Routes private-subnet outbound traffic               |

## Technologies Used

- **Amazon Web Services (AWS)**
- **Terraform**
- **Amazon VPC**
- **Public and Private Subnets**
- **Internet Gateway**
- **NAT Gateway**
- **Elastic IP**
- **Route Tables**
- **Security Groups**
- **AWS IAM**
- **Amazon EC2**
- **AWS Systems Manager Session Manager**
- **Amazon CloudWatch**

## Deployment Evidence

The following screenshots document selected resources and console states from the project.

### 1. Terraform Deployment

The Terraform output shows that the apply operation completed successfully.



### 2. VPC Configuration

The VPC details show the project's custom network and IPv4 CIDR block.



### 3. Public and Private Subnets

The VPC contains separate public and private subnets.



### 4. Route Tables

The public route table directs default traffic to the Internet Gateway, while the private route table directs default traffic to the NAT Gateway.



### 5. EC2 Instance

The following screenshot documents the EC2 instance in the AWS environment.



### 6. IAM Role and Permissions

The project uses an IAM role with the `AmazonSSMManagedInstanceCore` managed policy to support Systems Manager access.

The instance profile associates the IAM role with the EC2 instance.

### 7. CloudWatch Monitoring

A CloudWatch metric alarm monitors EC2 CPU utilization.

The alarm is configured to evaluate CPU utilization against a threshold of 80% over consecutive five-minute evaluation periods.

The screenshot shows the alarm in the `OK` state at the time it was captured. This indicates that the alarm was not breaching its configured threshold at that moment; it does not confirm that notifications were delivered.



## Security Considerations

Security is an important part of this project.

- Place workloads in private subnets when direct public access is unnecessary.
- Use IAM roles instead of storing long-term AWS credentials on EC2 instances.
- Use Systems Manager Session Manager for administrative access where configured.
- Restrict Security Group inbound rules to required sources and ports.
- Follow the principle of least privilege when assigning IAM permissions.
- Avoid exposing administrative services directly to the internet.
- Never commit AWS credentials, Terraform state files, or sensitive configuration files to GitHub.

**Important:** A NAT Gateway provides outbound connectivity; it does not make a private EC2 instance directly reachable from the internet. Systems Manager also requires a functioning SSM Agent, appropriate IAM permissions, and network connectivity to the required AWS endpoints.

## Prerequisites

Before deploying the infrastructure, ensure that you have:

- An AWS account with the required permissions.
- Terraform installed.
- AWS credentials configured through a supported authentication method.
- Access to the AWS region `us-east-1`.

## How to Deploy

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Format the configuration

```bash
terraform fmt
```

### 3. Validate the configuration

```bash
terraform validate
```

### 4. Review the execution plan

```bash
terraform plan
```

Review the proposed changes and expected costs before continuing.

### 5. Deploy the infrastructure

```bash
terraform apply
```

Confirm the operation only after reviewing the plan.

## Verification Checklist

Use this checklist to verify the infrastructure:

- [ ] Terraform formatting completes successfully.
- [ ] Terraform validation completes successfully.
- [ ] The execution plan contains only expected changes.
- [ ] The public subnet is associated with the public route table.
- [ ] The private subnet is associated with the private route table.
- [ ] The public default route targets the Internet Gateway.
- [ ] The private default route targets the NAT Gateway.
- [ ] The EC2 instance is deployed in the private subnet.
- [ ] Systems Manager Session Manager can connect to the instance.
- [ ] The CloudWatch alarm monitors the intended EC2 instance.
- [ ] Security Group rules follow the intended access requirements.

## Cost Management

Some resources used in this project may incur AWS charges, particularly:

- NAT Gateway
- Elastic IP addresses, depending on usage and AWS pricing rules
- EC2 instances
- CloudWatch features and additional monitoring services

Review the current AWS pricing for your region before deploying resources.

## Cleanup

When the infrastructure is no longer required, review the resources that Terraform proposes to remove:

```bash
terraform plan -destroy
```

If you are certain that the resources can be safely removed, run:

```bash
terraform destroy
```

Review the AWS console afterward to ensure that no unwanted billable resources remain.

## Repository Structure

A recommended structure for this project is:

```text
secure-aws-terraform-project/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── provider.tf
├── security.tf
├── iam.tf
├── compute.tf
├── cloudwatch.tf
├── .gitignore
├── terraform.tfvars.example
└── screenshots/
    ├── 03-terraform-apply-success.png
    ├── 04-vpc-details.png
    ├── 05-vpc-resource-map.png
    ├── 06-subnets-details.png
    ├── 08-route-tables.png
    ├── 10-ec2-instance-running.png
    └── 14-cloudwatch-cpu-alarm.png
```

This is a recommended structure. Keep your current Terraform files if your project uses a different layout; update the README paths if necessary.

## Future Improvements

Potential improvements include:

- Add input variables and validation rules.
- Pin compatible Terraform and AWS provider versions.
- Add useful outputs for important resource information.
- Configure Amazon SNS notifications for CloudWatch alarms if alert delivery is required.
- Consider VPC endpoints for Systems Manager.
- Run a Terraform security scanner such as Checkov.
- Add automated checks to a CI/CD workflow.
- Expand the monitoring configuration with additional metrics and alarms.

## Learning Outcomes

Through this project, I practised:

- AWS networking and subnet segmentation.
- Route table configuration and traffic routing.
- Internet Gateway and NAT Gateway concepts.
- Security Group configuration.
- IAM roles and instance profiles.
- Private EC2 administration through Systems Manager.
- CloudWatch metric monitoring.
- Infrastructure provisioning and lifecycle management with Terraform.

---

**Project:** Secure AWS Infrastructure with Terraform
**Cloud Provider:** Amazon Web Services
**Infrastructure as Code:** Terraform
**Region:** `us-east-1`
