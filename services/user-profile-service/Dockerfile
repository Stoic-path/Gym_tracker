# Imagen base oficial de Python (ligera)
FROM python:3.13.11-slim

# Evita que Python genere archivos .pyc y fuerza salida en consola en tiempo real
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Instalar dependencias del sistema necesarias (opcional pero recomendado para postgress/otros drivers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar dependencias e instalarlas
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente del proyecto
COPY . .

# Exponer el puerto estándar (interno del contenedor)
EXPOSE 8000

# Comando por defecto al iniciar
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]