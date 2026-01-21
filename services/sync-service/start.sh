#!/bin/bash
set -e # Detener script si hay error

echo "🚀 Starting Service..."

# 1. Esperar base de datos (Opcional pero recomendado si tienes script de espera)
# python wait_for_db.py 

# 2. Migraciones
echo "📦 Applying Migrations..."
python manage.py migrate --noinput

# 3. Seeding (Datos Iniciales)
if [ -f "seed_data.py" ]; then
    echo "wm Loading Seed Data..."
    python seed_data.py || echo "⚠️ Seed script failed/skipped (maybe duplicates), continuing..."
else
    echo "⚠️ No seed_data.py found."
fi

# 4. Iniciar Servidor (Ajusta el puerto según el servicio)
# IMPORTANTE: Reemplaza 8000 con el puerto correcto de CADA servicio:
# Auth: 8001, User: 8002, Cmd: 8003, Qry: 8004, Routine: 8005, Ex: 8006, etc.
PORT=8009 

echo "🔥 Running Server on 0.0.0.0:$PORT"
python manage.py runserver 0.0.0.0:$PORT