variable "aws_region" {
  description = "AWS Region where infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base project name used for resource naming"
  type        = string
  default     = "gym-tracker"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair (standard in Academy is vockey)"
  type        = string
  default     = "vockey" 
}

variable "instance_type_db" {
  description = "EC2 Instance type for Databases"
  type        = string
  default     = "t2.micro" 
}

variable "instance_type_app" {
  description = "EC2 Instance type for Microservices (ASG)"
  type        = string
  default     = "t2.micro" 
}