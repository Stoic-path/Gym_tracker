import os
import django
from pymongo import MongoClient
from datetime import datetime

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()
from django.conf import settings

# Obtener URI desde settings o variable de entorno
# Reconstruir URI con authenticación si es necesario para asegurar que el seed script funcione
MONGO_HOST = getattr(settings, 'MONGO_HOST', 'localhost')
MONGO_PORT = int(getattr(settings, 'MONGO_PORT', 27017))
MONGO_USER = getattr(settings, 'MONGO_USER', 'gym_user')
MONGO_PASS = getattr(settings, 'MONGO_PASS', 'gym_password_123')
MONGO_AUTH_SOURCE = getattr(settings, 'MONGO_AUTH_SOURCE', 'admin')

# Construir URI robusta
if MONGO_USER and MONGO_PASS:
    MONGO_URI = f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:{MONGO_PORT}/?authSource={MONGO_AUTH_SOURCE}"
else:
    MONGO_URI = f"mongodb://{MONGO_HOST}:{MONGO_PORT}/"
    
print(f"DEBUG: Connecting to MongoDB at {MONGO_HOST}:{MONGO_PORT} (User: {MONGO_USER}, AuthSource: {MONGO_AUTH_SOURCE})")

# UUID DETERMINISTA (El mismo de siempre)
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"

def seed_mongo():
    try:
        print("🌱 Connecting to MongoDB for Seeding...")
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        
        # Nombre de DB debe coincidir con settings.py (workout_query_db)
        db_name = getattr(settings, 'MONGO_DB_NAME', 'workout_query_db')
        db = client[db_name]
        
        # Verificar conexión
        client.server_info()
        print(f"✅ Connected to {db.name}")

        collection = db["workouts"]

        # Verificar si ya existen datos para este usuario
        if collection.count_documents({"user_id": ADMIN_UUID}) > 0:
            print(f"⚠️ Workouts for user {ADMIN_UUID} already exist. Skipping.")
            return

        print(f"🚀 Inserting sample workouts for {ADMIN_UUID}...")
        
        sample_workouts = [
            {
                "user_id": ADMIN_UUID,
                "name": "Chest Day Blast",
                "date": datetime.now().isoformat(),
                "duration_minutes": 65,
                "calories_burned": 450,
                "exercises": [
                    {"name": "Bench Press", "sets": 4, "reps": 10, "weight": 80},
                    {"name": "Incline Dumbbell Press", "sets": 3, "reps": 12, "weight": 25}
                ],
                "status": "completed"
            },
            {
                "user_id": ADMIN_UUID,
                "name": "Leg Day Survival",
                "date": datetime.now().isoformat(),
                "duration_minutes": 80,
                "calories_burned": 600,
                "exercises": [
                    {"name": "Squat", "sets": 5, "reps": 5, "weight": 120},
                    {"name": "Leg Extension", "sets": 3, "reps": 15, "weight": 50}
                ],
                "status": "completed"
            }
        ]

        collection.insert_many(sample_workouts)
        print("✅ Sample workouts inserted successfully!")

    except Exception as e:
        print(f"❌ Failed to seed MongoDB: {e}")

if __name__ == "__main__":
    seed_mongo()
