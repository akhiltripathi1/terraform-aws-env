terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Recommended for real use: uncomment and point at a remote backend
  # so state isn't left on a laptop.
  #
  # backend "s3" {
  #   bucket         = "my-tfstate-bucket"
  #   key            = "envs/demo/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "tf-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
