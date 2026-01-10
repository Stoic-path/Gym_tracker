#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# --- CORE DE NEGOCIO (EC2 #6) ---
# Workout Command/Query, Routine, Exercise Library

# 1. Workout Command (8003)
docker run -d --restart always \
  -p 8003:8003 \
  --name workout-command-service \
  -e MONGO_PORT=27017 \
  stoicpath/workout-command-service:latest

# 2. Workout Query (8004)
docker run -d --restart always \
  -p 8004:8004 \
  --name workout-query-service \
  -e MONGO_PORT=27017 \
  stoicpath/workout-query-service:latest

# 3. Routine Service (8005)
docker run -d --restart always \
  -p 8005:8005 \
  --name routine-service \
  -e DB_PORT=5432 \
  stoicpath/routine-service:latest

# 4. Exercise Library Service (8006)
docker run -d --restart always \
  -p 8006:8006 \
  --name exercise-library-service \
  -e MONGO_PORT=27017 \
  stoicpath/exercise-library-service:latest
