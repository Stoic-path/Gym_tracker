import os
import pymongo
import random
from datetime import datetime, timedelta
import uuid

# Configuración de conexión (Igual que settings.py)
MONGO_HOST = os.environ.get('MONGO_HOST', 'localhost')
MONGO_PORT = int(os.environ.get('MONGO_PORT', 27017))
MONGO_DB_NAME = os.environ.get('MONGO_DB_NAME', 'workout_query_db')

# Intentar conexión simple (sin auth) primero, ya que es lo que funcionó en tu infraestructura
MONGO_URI = f"mongodb://{MONGO_HOST}:{MONGO_PORT}/"

EXERCISES_LIST = ["Squat", "Bench Press", "Deadlift", "Overhead Press", "Pull Up", "Dips", "Lunges"]

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

    except Exception as e:
        print(f"❌ [Seed] Error conectando a Mongo: {e}")

if __name__ == '__main__':
    seed()