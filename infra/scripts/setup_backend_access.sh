#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Variables de entorno inyectadas por Terraform
DB_POSTGRES_HOST="${postgres_ip}"
DB_REDIS_HOST="${redis_ip}"

# --- ACCESO Y SINCRONIZACIÓN (EC2 #5) ---

# 1. Auth Service (8001)
docker pull stoicpath/auth-service:latest
docker run -d --restart always \
  -p 8001:8001 \
  --name auth-service \
  -e DB_HOST=$DB_POSTGRES_HOST \
  -e DB_PORT=5432 \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/auth-service:latest

# 2. User Profile Service (8002)
docker pull stoicpath/user-profile-service:latest
docker run -d --restart always \
  -p 8002:8002 \
  --name user-profile-service \
  -e DB_HOST=$DB_POSTGRES_HOST \
  -e DB_PORT=5432 \
  stoicpath/user-profile-service:latest

# 3. Sync Service (8009)
docker pull stoicpath/sync-service:latest
docker run -d --restart always \
  -p 8009:8009 \
  --name sync-service \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/sync-service:latest
