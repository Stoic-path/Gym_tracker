import os
import pymongo
import random
from datetime import datetime, timedelta
import uuid
import django
import datetime

# Configuración de conexión (Igual que settings.py)
MONGO_HOST = os.environ.get('MONGO_HOST', 'localhost')
MONGO_PORT = int(os.environ.get('MONGO_PORT', 27017))
MONGO_DB_NAME = os.environ.get('MONGO_DB_NAME', 'workout_query_db')

# Intentar conexión simple (sin auth) primero, ya que es lo que funcionó en tu infraestructura
MONGO_URI = f"mongodb://{MONGO_HOST}:{MONGO_PORT}/"

EXERCISES_LIST = ["Squat", "Bench Press", "Deadlift", "Overhead Press", "Pull Up", "Dips", "Lunges"]

# Asumimos que tienes modelos o usas PyMongo directo. 
# Si usas Djongo/Models, adáptalo. Aquí un ejemplo genérico:
from queries.models import WorkoutHistory # Ajusta según tu modelo real

# EL MISMO UUID DETERMINISTA
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"

def seed():
    try:
        client = pymongo.MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        db = client[MONGO_DB_NAME]
        collection = db['workouts']

        # Idempotencia
        if collection.count_documents({}) >= 100:
            print("✅ [Seed] Workout Query: Ya existen 100+ entrenamientos. Saltando seed.")
            return

        print("🌱 [Seed] Workout Query: Insertando 100 entrenamientos...")
        workouts = []
        for i in range(100):
            email = f"user_{i}@gymtracker.com"
            user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            
            workouts.append({
                "user_id": user_id,
                "name": f"Workout Session {i}",
                "date": (datetime.now() - timedelta(days=i)).isoformat(),
                "duration_minutes": random.randint(30, 90),
                "calories_burned": random.randint(200, 600),
                "exercises": random.sample(EXERCISES_LIST, k=3),
                "status": "completed"
            })
        
        collection.insert_many(workouts)
        print("✅ [Seed] Workout Query: Carga completa.")

        # Verificar si ya existe alguna rutina de este usuario
        if WorkoutHistory.objects.filter(user_id=ADMIN_UUID).exists():
            print("⚠️  Workouts for Admin already exist.")
            return

        print(f"🌱 Seeding mongo Workouts for UUID {ADMIN_UUID}...")
        
        WorkoutHistory.objects.create(
            user_id=ADMIN_UUID, # ENLACE CRÍTICO
            workout_name="Full Body Intro",
            date=datetime.date.today(),
            duration_minutes=45,
            calories_burned=300
        )
        print("✅ MongoDB Workouts seeded.")

    except Exception as e:
        print(f"❌ [Seed] Error conectando a Mongo: {e}")

if __name__ == '__main__':
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
    django.setup()
    seed()