#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# --- PROCESAMIENTO PESADO (EC2 #7) ---
# Video, Notification, Analytics

# 1. Video Service (8007)
docker run -d --restart always \
  -p 8007:8007 \
  --name video-service \
  -e MONGO_PORT=27017 \
  stoicpath/video-service:latest

# 2. Notification Service (8008)
docker run -d --restart always \
  -p 8008:8008 \
  --name notification-service \
  -e REDIS_PORT=6379 \
  stoicpath/notification-service:latest

# 3. Analytics Service (8010)
docker run -d --restart always \
  -p 8010:8010 \
  --name analytics-service \
  -e DB_PORT=5432 \
  stoicpath/analytics-service:latest
