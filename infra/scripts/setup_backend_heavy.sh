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
TAG="${image_tag}"

# --- PROCESAMIENTO PESADO (EC2 #7) ---
# Video, Notification, Analytics

# 1. Video Service (8007)
docker pull stoicpath/video-service:$TAG
docker run -d --restart always \
  -p 8007:8000 \
  --name video-service \
  -e MONGO_HOST=$DB_MONGO_HOST \
  -e MONGO_PORT=27017 \
  stoicpath/video-service:$TAG

# Inicialización Video
sleep 5
docker exec video-service python manage.py migrate

# 2. Notification Service (8008)
docker pull stoicpath/notification-service:$TAG
docker run -d --restart always \
  -p 8008:8000 \
  --name notification-service \
  -e REDIS_HOST=$DB_REDIS_HOST \
  -e REDIS_PORT=6379 \
  stoicpath/notification-service:$TAG

# Inicialización Notification
sleep 5
docker exec notification-service python manage.py migrate

# 3. Analytics Service (8010)
docker pull stoicpath/analytics-service:$TAG
docker run -d --restart always \
  -p 8010:8000 \
  --name analytics-service \
  -e DATABASE_URL="postgres://gym_user:gym_password_123@$DB_POSTGRES_HOST:5432/analytics_db" \
  stoicpath/analytics-service:$TAG

# Inicialización Analytics (CRÍTICO: Usa Postgres)
sleep 5
docker exec analytics-service python manage.py migrate
