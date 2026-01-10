from django.core.management.base import BaseCommand
from django.conf import settings
import pymongo
from datetime import datetime

class Command(BaseCommand):
    help = 'Seeds MongoDB with sample workout history'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding Mongo Workouts...')
        
        # Connect to Mongo
        client = pymongo.MongoClient(settings.MONGO_URI)
        db = client['gym_workouts_db'] # Explicit DB name
        collection = db['workouts']
        
        # Clean old data
        collection.delete_many({})
        
        # Insert seed data
        workouts = [
            {
                "name": "Full Body Crush (From Mongo)",
                "date": datetime.now(),
                "duration": 45,
                "exercises": [
                    {"name": "Squat", "sets": 3, "reps": 12},
                    {"name": "Bench Press", "sets": 3, "reps": 10},
                    {"name": "Rows", "sets": 3, "reps": 12}
                ]
            },
            {
                "name": "Cardio Blast (From Mongo)",
                "date": datetime.now(),
                "duration": 30,
                "exercises": [
                    {"name": "Treadmill", "sets": 1, "reps": 1500} # 1.5km
                ]
            }
        ]
        
        collection.insert_many(workouts)
        
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(workouts)} workouts into MongoDB!'))
