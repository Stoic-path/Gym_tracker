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

# --- SERVICE GROUPS (Target Groups Config) ---

variable "tg_access_group" {
  description = "Target groups configuration for Access/Sync Cluster"
  default = {
    "auth" = { port = 8001, path = "/api/auth" }
    "user" = { port = 8002, path = "/api/users" }
    "sync" = { port = 8009, path = "/api/sync" }
  }
}

variable "tg_core_group" {
  description = "Target groups configuration for Core Business Cluster"
  default = {
    "work_cmd" = { port = 8003, path = "/api/workouts/command" }
    "work_qry" = { port = 8004, path = "/api/workouts/query" }
    "routine"  = { port = 8005, path = "/api/routines" }
    "exercise" = { port = 8006, path = "/api/exercises" }
  }
}

variable "tg_heavy_group" {
  description = "Target groups configuration for Heavy Processing Cluster"
  default = {
    "video"     = { port = 8007, path = "/api/videos" }
    "notify"    = { port = 8008, path = "/api/notifications" }
    "analytics" = { port = 8010, path = "/api/analytics" }
  }
}
