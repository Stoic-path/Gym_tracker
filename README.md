# GymTrack Cloud

Sistema de seguimiento de entrenamiento de fuerza distribuido para la Universidad Central del Ecuador.

## 🏗️ Arquitectura del Proyecto

Este repositorio es un **Monorepo Políglota** gestionado con **Moonrepo**. Integra servicios de Backend en Python y aplicaciones de Frontend en JavaScript/Dart.

### Estructura General
* **`apps/`**: Aplicaciones Cliente (Mobile, Web, Desktop).
* **`services/`**: Microservicios Backend (Django REST Framework).
* **`packages/`**: Librerías compartidas y lógica de negocio común.
* **`infra/`**: Infraestructura como Código (Terraform).

---

## 🛠️ Herramientas de Desarrollo (Dev Tools)

Para levantar el entorno de desarrollo y colaborar en este repositorio, asegúrate de tener instalado lo siguiente:

### Requisitos Globales
Estas herramientas deben estar instaladas en tu sistema operativo para ejecutar los scripts de inicialización y orquestación:

* **Lenguajes Base:**
    * **Python:** `3.13.11` (Requerido para Backend y Scripts de Scaffolding).
    * **Node.js:** `v24.12.0` (Requerido para el entorno de Frontend).

* **Gestores de Paquetes:**
    * **`pip`**: Para instalar dependencias globales de Python (ej: Django).
    * **`pnpm`**: Para gestionar dependencias de Node y Workspaces.
        * *Instalación:* `npm install -g pnpm`

* **Orquestador:**
    * **Moonrepo:** Herramienta de gestión del monorepo.
        * *Instalación:* `npm install -g @moonrepo/cli`

---

## 🚀 Inicialización Rápida

### 1. Backend (Django)
Para generar nuevos microservicios o ejecutar comandos de Django, asegúrate de tener las librerías base:

```bash
# Instalación de herramientas de scaffolding
py -m pip install "django>=5.0" "djangorestframework>=3.14"

### 2. Frontend & Toolchain (Raíz del Monorepo)
Una vez clonado el repositorio, instala las dependencias del espacio de trabajo (incluyendo la configuración de Moonrepo) ejecutando en la raíz:

```bash
pnpm install

