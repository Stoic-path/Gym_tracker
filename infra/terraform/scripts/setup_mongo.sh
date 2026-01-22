#!/bin/bash
set -e # Stop script on error

# --- 1. Repository Configuration ---
echo "Adding MongoDB 7.0 repository..."
echo "[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo

# --- 2. Installation ---
echo "Updating system and installing MongoDB..."
dnf update -y
dnf install -y mongodb-org

# --- 3. Network Configuration ---
echo "Configuring remote access (Bind IP)..."
MONGOD_CONF="/etc/mongod.conf"

# Change bindIp from 127.0.0.1 to 0.0.0.0 to allow connections from other microservices in the VPC
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' $MONGOD_CONF

# Start and enable the service
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to fully start before running commands
echo "Waiting for MongoDB to initialize..."
sleep 10

# --- 4. Database & User Initialization (JavaScript) ---
echo "Creating admin user and logical databases..."

# Run mongosh commands to initialize data
mongosh <<EOF
// Switch to admin database to create the root user
use admin
db.createUser({
  user: "gym_user",
  pwd: "gym_password_123",
  roles: [ { role: "root", db: "admin" } ]
})

// --- Database Seeding ---
// MongoDB creates databases lazily (only when data is inserted).
// We create a dummy collection in each DB to force their creation so Djongo can find them.

use workout_command_db
db.createCollection("init_marker")
db.init_marker.insertOne({ status: "initialized" })

use workout_query_db
db.createCollection("init_marker")
db.init_marker.insertOne({ status: "initialized" })

use exercise_lib_db
db.createCollection("init_marker")
db.init_marker.insertOne({ status: "initialized" })

use video_db
db.createCollection("init_marker")
db.init_marker.insertOne({ status: "initialized" })

EOF

echo "✅ MongoDB provisioning complete."