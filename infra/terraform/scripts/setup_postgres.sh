#!/bin/bash
set -e # Stop script on error

# --- 1. Installation ---
echo "Updating system and installing PostgreSQL 15..."
dnf update -y
dnf install -y postgresql15-server postgresql15

# --- 2. Initialization ---
echo "Initializing database..."
postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql

# --- 3. Network Configuration (CRITICAL for remote access) ---
PG_DATA="/var/lib/pgsql/data"
PG_CONF="$PG_DATA/postgresql.conf"
PG_HBA="$PG_DATA/pg_hba.conf"

echo "Configuring remote access..."
# Allow listening on all interfaces (0.0.0.0) instead of just localhost
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

# Allow password authentication (md5) from any IP (0.0.0.0/0)
# Appended to the end of the file to ensure priority
echo "host    all             all             0.0.0.0/0               md5" >> $PG_HBA

# Restart service to apply network changes
systemctl restart postgresql

# --- 4. Structure Creation (SQL) ---
echo "Creating users and databases..."

# Execute psql as the system 'postgres' user
sudo -u postgres psql <<EOF
-- Stop execution if an error occurs
\set ON_ERROR_STOP on

-- Create application user
-- In production, passwords should come from Secrets Manager. Hardcoded here for Academy.
CREATE USER gym_user WITH PASSWORD 'gym_password_123';
ALTER USER gym_user CREATEDB;

-- Create Logical Databases for microservices
CREATE DATABASE auth_db OWNER gym_user;
CREATE DATABASE user_profile_db OWNER gym_user;
CREATE DATABASE routine_db OWNER gym_user;
CREATE DATABASE analytics_db OWNER gym_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE auth_db TO gym_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile_db TO gym_user;
GRANT ALL PRIVILEGES ON DATABASE routine_db TO gym_user;
GRANT ALL PRIVILEGES ON DATABASE analytics_db TO gym_user;
EOF

echo "✅ PostgreSQL provisioning complete."