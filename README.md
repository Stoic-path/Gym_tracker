# GymTrack Cloud 🏋️‍♂️☁️

**Distributed Workout Tracking System** *Faculty of Physical Education - Universidad Central del Ecuador*

## 📖 Project Overview

GymTrack Cloud is a distributed system designed to track strength training, routines, and physical progress. Based on the **DraftReport3** specifications, this project implements a **Microservices Architecture** with **Polyglot Persistence**, tailored for a high-concurrency academic environment.

The system supports multiple client platforms (Web, Mobile, Desktop) and manages data flow through a hybrid infrastructure of Relational, Document-oriented, and Key-Value databases.

---

## 🏗 Architecture & Monorepo Structure

This repository is a **Polyglot Monorepo** managed by **Moonrepo**. It organizes the codebase into three main workspaces to support the multi-platform requirements outlined in the technical report.

### Directory Structure

* **`apps/`**: Client-side applications.
    * `web/`: React application for Users and Admin dashboard.
    * *(Planned)* `mobile/`: Flutter application for gym tracking.
    * *(Planned)* `desktop/`: Electron/Tauri app for kiosk mode.
* **`services/`**: The 10 Backend Microservices (Django REST Framework).
* **`packages/`**: Shared libraries, UI kits, and common logic.
* **`infra/`**: Infrastructure as Code (Terraform & Docker).

---

## 🧩 Microservices & Infrastructure Map

In accordance with the architectural definitions, the system is divided into domain-specific services, each with its own database responsibility.

| Service Name | Port | Database | Pattern/Type | Responsibility |
| :--- | :--- | :--- | :--- | :--- |
| **Auth Service** | `8001` | Postgres + Redis | Hybrid | Identity, JWT, Session mgmt |
| **User Profile** | `8002` | Postgres | Relational | Demographics, Body measurements |
| **Routine** | `8005` | Postgres | Relational | Training plans structure |
| **Analytics** | `8010` | Postgres | Analytical | Progress stats & Reporting |
| **Workout Cmd** | `8003` | MongoDB | **CQRS (Write)** | High-volume workout logging |
| **Workout Query** | `8004` | MongoDB | **CQRS (Read)** | Workout history retrieval |
| **Exercise Lib** | `8006` | MongoDB | Document | Catalog of exercises/equipment |
| **Video** | `8007` | MongoDB | Document | Metadata for instructional videos |
| **Notification** | `8008` | Redis | Queue | Async Email/Push delivery |
| **Sync** | `8009` | Redis | Queue | Offline/Online synchronization |
| **Web Client** | `3000` | N/A | SPA | Frontend Interface |

### Data Infrastructure (Dockerized)
* **PostgreSQL 15** (`:5432`): Primary Source of Truth for structured data.
* **MongoDB 6** (`:27017`): Document store for polymorphic data (Workouts/Videos).
* **Redis 7** (`:6379`): In-memory cache, session store, and message broker.

---

## 🛠 Prerequisites

To run this project, you need the following tools installed globally:

1.  **Container Runtime:** Docker Desktop & Docker Compose.
2.  **Monorepo Toolchain:**
    * Node.js (v20+) & `pnpm`
    * Moonrepo: `npm install -g @moonrepo/cli`
3.  **Language Runtimes (for local dev):**
    * Python 3.13+

---

## 🚀 Getting Started

### 1. Infrastructure Setup (Docker)
The recommended way to run the full system is via Docker Compose, which simulates the AWS EC2 topology.

```bash
# 1. Clone the repository
git clone <repo-url>
cd Gym_tracker

# 2. Build and Start all services and databases
docker compose up --build -d

# 3. Check status
docker compose ps
```
### 2. Database Initialization
Once containers are running, apply migrations to initialize the PostgreSQL schemas. MongoDB and Redis do not require schema migrations.
```bash
# Initialize Auth (Users/Groups)
docker compose exec auth-service python manage.py migrate

# Initialize other Relational Services
docker compose exec user-profile-service python manage.py migrate
docker compose exec routine-service python manage.py migrate
docker compose exec analytics-service python manage.py migrate
```
### 3. Development Workflow (Moonrepo)
Use Moonrepo to run tasks across the monorepo without Dockerizing everything (useful for quick logic iteration).
```bash
# Install workspace dependencies
pnpm install

# Run linting across all 10 microservices
moon run :lint

# Run unit tests for a specific service
moon run auth-service:test

# Start the Web Frontend locally
moon run web:dev
```
## ☁️ Deployment Strategy

The architecture supports multiple deployment environments:

### Local Development
* **Docker Compose**: Current setup for local development and testing.

### Cloud (AWS)
The architecture is designed to be deployed on AWS EC2 instances managed by Terraform, adhering to the "Infrastructure Cost Estimation" section of the report.

| Component | AWS Service | Description |
| :--- | :--- | :--- |
| **PostgreSQL** | EC2 Instance | Primary relational database server |
| **MongoDB** | EC2 Instance | Document store server |
| **Microservices** | EC2 / Auto Scaling Groups | Application layer with horizontal scaling |