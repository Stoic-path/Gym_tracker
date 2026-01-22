terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Common tags for all resources
  default_tags {
    tags = {
      Project     = "GymTracker"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}