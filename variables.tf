variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name used as a prefix on all resources"
  type        = string
  default     = "demo-env"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the app servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to run behind the ALB (one per private subnet, cycled)"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access via the bastion/SSM. Leave null to disable key-based SSH."
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into instances (only used if key_pair_name is set). Restrict this to your own IP."
  type        = string
  default     = "0.0.0.0/0"
}

variable "s3_force_destroy" {
  description = "Allow terraform destroy to delete the S3 bucket even if it still has objects"
  type        = bool
  default     = true
}
