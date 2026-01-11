#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Variables de entorno inyectadas por Terraform
DB_POSTGRES_HOST="${postgres_ip}"
DB_REDIS_HOST="${redis_ip}"
TAG="${image_tag}"

# --- ACCESO Y SINCRONIZACIÓN (EC2 #5) ---

# 1. Auth Service (8001)
docker pull stoicpath/auth-service:$TAG
docker run -d --restart always \
  -p 8001:8001 \
  --name auth-service \
  -e DATABASE_URL="postgres://gym_user:gym_password_123@$DB_POSTGRES_HOST:5432/auth_db" \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/auth-service:$TAG

# 2. User Profile Service (8002)
docker pull stoicpath/user-profile-service:$TAG
docker run -d --restart always \
  -p 8002:8002 \
  --name user-profile-service \
  -e DATABASE_URL="postgres://gym_user:gym_password_123@$DB_POSTGRES_HOST:5432/user_profile_db" \
  stoicpath/user-profile-service:$TAG

# 3. Sync Service (8009)
docker pull stoicpath/sync-service:$TAG
docker run -d --restart always \
  -p 8009:8009 \
  --name sync-service \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/sync-service:$TAG
