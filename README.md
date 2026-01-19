# Gym Tracker Distributed System

Distributed gym tracking system based on microservices, deployed on AWS using **ECS Fargate** for compute and **EC2** for the data persistence layer.

## 📋 Table of Contents
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Infrastructure Management (AWS Academy)](#-infrastructure-management-aws-academy)
- [Deployment and Build](#-deployment-and-build)
- [Verification and Debugging](#-verification-and-debugging)
- [Manual Database Commands](#-manual-database-commands)

## 🏗 Architecture
The system consists of:
- **Frontend**: React (SPA) served by Nginx in containers.
- **Backend**: 10+ Django/Python Microservices (Auth, User, Workout, Analytics, etc.).
- **Databases (Hosted on EC2)**:
  - **PostgreSQL**: Relational data (Users, Profiles, Routines).
  - **MongoDB**: Document data (Workout History, Videos).
  - **Redis**: Cache, Message Queues, and Sessions.
- **AWS Infrastructure**:
  - **ECS Fargate**: Serverless container orchestration.
  - **ALB (Application Load Balancer)**: Path-based traffic routing (`/api/auth`, `/api/workouts`, etc.).
  - **VPC**: Private network for services/DBs and public for ALB/Bastion/NAT.

## 🛠 Prerequisites
- AWS CLI installed.
- Terraform installed.
- Docker Desktop running.
- PowerShell (to run utility scripts).
- `labsuser.pem` file (downloaded from AWS Academy) located in `infra/terraform/environments/develop/`.

## 🚀 Infrastructure Management (AWS Academy)
Because AWS Academy credentials expire frequently, use these scripts to manage the lifecycle.

### 1. Switch Credentials (`switch_account.ps1`)
**Location:** `infra/terraform/environments/develop/switch_account.ps1`

This script is **CRITICAL**. Run it every time you start a new session in AWS Academy or when the token expires.
- Updates credentials in your local environment.
- Updates **GitHub Secrets** so CI/CD keeps working.
- Cleans corrupt Terraform state.
- Runs `terraform apply` to provision or update infrastructure.

```powershell
./infra/terraform/environments/develop/switch_account.ps1
```

## 🐳 Despliegue y Construcción

### Levantar Infraestructura (AWS)
Para desplegar (levantar) toda la infraestructura en AWS desde cero o aplicar cambios:

```powershell
# Este script inicializa Terraform y aplica la configuración
./infra/terraform/environments/develop/switch_account.ps1
```

### Construir y Subir Imágenes (`build_and_push.ps1`)
**Ubicación:** `infra/terraform/environments/develop/build_and_push.ps1`

Compila las imágenes Docker de todos los microservicios y el frontend, y las sube a Amazon ECR.
- Etiqueta las imágenes como `:dev` y `:latest` para asegurar compatibilidad.
- Requiere que Docker esté corriendo.

```powershell
./infra/terraform/environments/develop/build_and_push.ps1
```

## 🔍 Verificación y Debugging

### Conexión al Bastion Host (`connect_ssh.ps1`)
**Ubicación:** `infra/terraform/environments/develop/connect_ssh.ps1`

Conecta automáticamente por SSH a la instancia **Bastion Host**.
- Busca dinámicamente la IP pública de la instancia Bastion.
- Usa la llave `labsuser.pem` para autenticar.

```powershell
./infra/terraform/environments/develop/connect_ssh.ps1
```

### Script de Verificación de Bases de Datos (`./verify_dbs.sh`)
**Contexto:** Este script **NO** está en tu repositorio local. Se genera **automáticamente** dentro del servidor Bastion (EC2) cada vez que Terraform despliega la infraestructura. Terraform inyecta las IPs privadas correctas de las bases de datos en este script.

**Para qué sirve:** Verifica instantáneamente si las bases de datos (Postgres, Mongo, Redis) están accesibles y si tienen datos (semillas).

**Pasos para usarlo:**
1. Conéctate al Bastion usando `connect_ssh.ps1`.
2. Una vez dentro de la terminal Linux (`[ec2-user@... ~]$`), ejecuta:

```bash
./verify_dbs.sh
```

**Salida esperada:**
- **PostgreSQL**: Muestra el conteo de usuarios (debería ser >100 si el seed corrió).
- **MongoDB**: Muestra el conteo de documentos de entrenamientos.
- **Redis**: Muestra el tamaño de la caché.

## 💻 Comandos Manuales de Base de Datos
Si necesitas explorar las bases de datos manualmente desde el Bastion Host (porque están en una red privada), usa estos comandos.

> **Nota:** Necesitas obtener las IPs privadas ejecutando `terraform output database_ips` en tu máquina local o viendo el contenido de `verify_dbs.sh` en el Bastion (`cat verify_dbs.sh`).

### PostgreSQL
```bash
# Conectar a la base de datos de autenticación
PGPASSWORD='gym_password_123' psql -h <IP_PRIVADA_POSTGRES> -U gym_user -d auth_db
```

### MongoDB
```bash
# Conectar a la base de datos de consultas de entrenamientos
mongosh "mongodb://<IP_PRIVADA_MONGO>:27017/workout_query_db"
```

### Redis
```bash
# Verificar conexión y claves
redis-cli -h <IP_PRIVADA_REDIS> -p 6379 ping
redis-cli -h <IP_PRIVADA_REDIS> -p 6379 dbsize
```