from django.core.management.base import BaseCommand
from django.conf import settings
import pymongo
from datetime import datetime
import uuid

class Command(BaseCommand):
    help = 'Seeds MongoDB with sample workout history'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding Mongo Workouts...')
        
        # Connect to Mongo
        client = pymongo.MongoClient(settings.MONGO_URI)
        db = client['workout_query_db'] # Explicit DB name
        collection = db['workouts']
        
        # Idempotencia: Si ya hay datos, no hacemos nada
        if collection.count_documents({}) > 0:
            self.stdout.write(self.style.SUCCESS('Data already exists in MongoDB. Skipping seed.'))
            return
        
        # Insert seed data
        workouts = []
        
        # Generar workouts para los 100 usuarios deterministas
        for i in range(100):
            email = f"user_{i}@gymtracker.com"
            user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            
            workouts.append({
                "user_id": user_id,
                "name": f"Rutina Aleatoria #{i}",
                "date": datetime.now(),
                "duration": 60,
                "exercises": [
                    {"name": "Burpees", "sets": 4, "reps": 15}
                ]
            })
        
        collection.insert_many(workouts)
        
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(workouts)} workouts into MongoDB!'))
