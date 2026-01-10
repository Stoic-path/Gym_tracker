#!/bin/bash
set -e # Stop script on error

# --- 1. Installation ---
echo "Updating system and installing Redis 6..."
dnf update -y
dnf install -y redis6

# --- 2. Configuration ---
REDIS_CONF="/etc/redis6/redis6.conf"

echo "Configuring Redis network binding..."

# By default Redis binds to 127.0.0.1. We change it to 0.0.0.0 to allow VPC connections.
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' $REDIS_CONF

# Disable protected mode because we are binding to public interface (internal VPC security relies on Security Groups)
sed -i 's/protected-mode yes/protected-mode no/' $REDIS_CONF

# --- 3. Security (Optional) ---
# Uncomment the following line if you want to enforce a password for Redis
# echo "requirepass gym_password_123" >> $REDIS_CONF

# --- 4. Start Service ---
echo "Starting Redis service..."
systemctl start redis6
systemctl enable redis6

echo "✅ Redis provisioning complete."