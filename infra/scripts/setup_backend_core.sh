#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Variables de entorno
DB_POSTGRES_HOST="${postgres_ip}"
DB_MONGO_HOST="${mongo_ip}"
TAG="${image_tag}"

# --- CORE DE NEGOCIO (EC2 #6) ---
# Workout Command/Query, Routine, Exercise Library

# 1. Workout Command (8003)
docker pull stoicpath/workout-command-service:$TAG
docker run -d --restart always \
  -p 8003:8000 \
  --name workout-command-service \
  -e MONGO_HOST=$DB_MONGO_HOST \
  -e MONGO_PORT=27017 \
  stoicpath/workout-command-service:$TAG

# Inicialización Workout Command
sleep 5
docker exec workout-command-service python manage.py migrate

# 2. Workout Query (8004)
docker pull stoicpath/workout-query-service:$TAG
docker run -d --restart always \
  -p 8004:8000 \
  --name workout-query-service \
  -e MONGO_HOST=$DB_MONGO_HOST \
  -e MONGO_PORT=27017 \
  stoicpath/workout-query-service:$TAG

# Inicialización Workout Query
sleep 5
docker exec workout-query-service python manage.py migrate

# 3. Routine Service (8005)
docker pull stoicpath/routine-service:$TAG
docker run -d --restart always \
  -p 8005:8000 \
  --name routine-service \
  -e DATABASE_URL="postgres://gym_user:gym_password_123@$DB_POSTGRES_HOST:5432/routine_db" \
  stoicpath/routine-service:$TAG

# Inicialización Routine (CRÍTICO: Usa Postgres)
sleep 5
docker exec routine-service python manage.py migrate

# 4. Exercise Library Service (8006)
docker pull stoicpath/exercise-library-service:$TAG
docker run -d --restart always \
  -p 8006:8000 \
  --name exercise-library-service \
  -e MONGO_HOST=$DB_MONGO_HOST \
  -e MONGO_PORT=27017 \
  stoicpath/exercise-library-service:$TAG

# Inicialización Exercise Library
sleep 5
docker exec exercise-library-service python manage.py migrate
