#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Variables de entorno
DB_POSTGRES_HOST="${postgres_ip}"
DB_MONGO_HOST="${mongo_ip}"
DB_REDIS_HOST="${redis_ip}"

# --- PROCESAMIENTO PESADO (EC2 #7) ---
# Video, Notification, Analytics

# 1. Video Service (8007)
docker pull stoicpath/video-service:latest
docker run -d --restart always \
  -p 8007:8007 \
  --name video-service \
  -e MONGO_HOST=$DB_MONGO_HOST \
  -e MONGO_PORT=27017 \
  stoicpath/video-service:latest

# 2. Notification Service (8008)
docker pull stoicpath/notification-service:latest
docker run -d --restart always \
  -p 8008:8008 \
  --name notification-service \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/notification-service:latest

# 3. Analytics Service (8010)
docker pull stoicpath/analytics-service:latest
docker run -d --restart always \
  -p 8010:8010 \
  --name analytics-service \
  -e DB_HOST=$DB_POSTGRES_HOST \
  -e DB_PORT=5432 \
  stoicpath/analytics-service:latest
