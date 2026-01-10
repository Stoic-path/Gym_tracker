# GymTrack Cloud 🏋️‍♂️☁️

**Distributed Workout Tracking System** *Faculty of Physical Education - Universidad Central del Ecuador*

## 📖 Project Overview

GymTrack Cloud is a distributed system designed to track strength training, routines, and physical progress. This project implements a **Microservices Architecture** with **Polyglot Persistence**, tailored for a high-concurrency academic environment and deployed on AWS using Infrastructure as Code (IaC).

The system supports multiple client platforms (Web, Mobile, Desktop) and manages data flow through a hybrid infrastructure of Relational, Document-oriented, and Key-Value databases.

---

## 🏗 Architecture & Monorepo Structure

This repository is a **Polyglot Monorepo** managed by **Moonrepo**. It organizes the codebase into three main workspaces.

### Directory Structure

* **`apps/`**: Client-side applications.
    * `web/`: React application (Vite) for Users and Admin dashboard.
    * *(Planned)* `mobile/`: Flutter application.
    * *(Planned)* `desktop/`: Electron/Tauri app.
* **`services/`**: The 10 Backend Microservices (Django REST Framework).
* **`packages/`**: Shared libraries and UI kits.
* **`infra/`**: Infrastructure as Code (Terraform) and Setup Scripts.

---

## 🧩 Microservices & Infrastructure Map

The system is divided into domain-specific services, communicating via HTTP/REST within a private VPC.

| Service Name | Port | Database | Technology | Responsibility |
| :--- | :--- | :--- | :--- | :--- |
| **Auth Service** | `8001` | Postgres | Django/SQL | Identity, JWT, RBAC |
| **User Profile** | `8002` | Postgres | Django/SQL | Demographics, Body measurements |
| **Routine** | `8006` | Postgres | Django/SQL | Training plans structure |
| **Analytics** | `8007` | Postgres | Django/SQL | Progress stats & Reporting |
| **Notification** | `8008` | Postgres* | Django/SQL | Async Email/Push logs (*Uses Redis for Queue) |
| **Workout Cmd** | `8003` | MongoDB | Django/Djongo | **CQRS (Write)** - Workout logging |
| **Workout Query** | `8004` | MongoDB | Django/Djongo | **CQRS (Read)** - History retrieval |
| **Exercise Lib** | `8005` | MongoDB | Django/Djongo | Catalog of exercises |
| **Video** | `8009` | MongoDB | Django/Djongo | Video Metadata |
| **Sync** | `8010` | Redis* | Django/SQLite | Offline sync state (*Uses Redis as primary store) |
| **Web Client** | `80` | N/A | React/Nginx | Frontend Interface served via ALB |

### Cloud Infrastructure (AWS)
* **Application Load Balancer (ALB):** Public entry point, handles SSL and routing rules.
* **Auto Scaling Groups (ASG):** One ASG per microservice for high availability.
* **Polyglot Persistence Layer (EC2):**
    * **PostgreSQL:** Primary relational store.
    * **MongoDB:** Document store for complex structures.
    * **Redis:** In-memory cache and message broker.

---

## 🛠 Prerequisites

To develop or deploy this project, you need:

1.  **Development:**
    * Node.js (v20+) & `pnpm`
    * Python 3.10+
    * Moonrepo: `npm install -g @moonrepo/cli`
    * Docker Desktop
2.  **Deployment (DevOps):**
    * Terraform (v1.5+)
    * AWS CLI (configured with valid credentials)

---

## 🚀 Getting Started (Local Development)

The recommended way to run the full system locally is via Docker Compose.

```bash
# 1. Clone the repository
git clone <repo-url>
cd Gym_tracker

# 2. Build and Start all services
docker compose up --build -d

# 3. Check status
docker compose ps
```

### Moonrepo Workflow
Use Moonrepo for fast local linting and testing without full containerization.

```bash
# Install dependencies
pnpm install

# Run linting across all services
moon run :lint

# Run tests for a specific service
moon run auth-service:test

# Start frontend locally
moon run web:dev
```

---

## ☁️ Deployment Guide (AWS)
This project uses Terraform to provision the infrastructure and GitHub Actions for CI/CD.

### 1. Infrastructure Provisioning (Terraform)

We use a "Fire and Forget" strategy for the initial infrastructure creation.

```bash
cd infra/terraform/environments/develop

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure (Creates VPC, EC2s, ALB, ASGs)
terraform apply
```

> **Note:** This generates the `alb_dns_name` and private `database_ips` required for the application configuration.

### 2. Continuous Deployment (CI/CD)

The software delivery is automated via GitHub Actions:

* **CI:** Builds Docker images for all services and pushes them to DockerHub.
* **CD:** Triggers an Instance Refresh in AWS Auto Scaling Groups to pull the new images and update the running containers with zero downtime.

### 3. Environment Configuration

The services are configured to be Cloud Native. They automatically detect whether they are running locally (Docker Compose) or in AWS (Terraform) by checking environment variables:

* `DB_HOST`: Injected by Terraform User Data.
* `REDIS_HOST`: Injected by Terraform User Data.
* `VITE_API_URL`: Configured in Frontend build time.

